require 'open-uri'
require 'digest/sha1'
require 'socket'
require 'ngrok/tunnel'
require 'json'
require_relative 'binary.rb'
require_relative 'routing_table.rb'
require_relative 'contact.rb'
require_relative 'network_adapter.rb'
require_relative 'storage.rb'

class Node
  attr_reader :ip, :port, :id, :files, :routing_table, :dht_segment, :is_super, :superport, :manifests, :shards
  def initialize(num_string, network, port='80')
    @port = port
    @network = network
    join(@network)
    @id = num_string
    @routing_table = RoutingTable.new(self)
    generate_file_cache
    generate_manifest_cache
    generate_shard_cache
    @dht_segment = {}
    @is_super = false
    @superport = nil
  end

  def set_super
    @is_super = ENV['SUPER'] == 'true'
  end

  def activate(port)
    set_ip(port)
    @superport = ENV['SUPERPORT']
    return if is_super
    @super_ip = ENV['SUPERIP'] || @ip
    result = JSON.parse(@network.info(@super_ip, @superport))
    contact = Contact.new(id: result['id'], ip: result['ip'], port: result['port'])
    ping(contact)
    Thread.new do
      iterative_find_node(@id)
      broadcast
    end
  end

  def broadcast
    [@manifests, @shards].each do |hash|
      hash.each do |k, v|
        iterative_store(k, file_url(v))
      end
    end
  end

  def generate_file_cache
    @files = {}

    Dir.glob(File.expand_path(Defaults::ENVIRONMENT[:files] + '/*')).select { |f| File.file?(f) }.each do |file|
      file_hash = generate_file_id(File.read(file))
      @files[file_hash] = '/files/' + File.basename(file)
    end
  end

  def get(url)
    file = @network.get(url)

    if file
      if File.extname(url) == '.xro'
        add_manifest(file.body, File.basename(url, File.extname(url)))
        compile_shards(file.body, File.basename(url))
      else
        add_shard(File.basename(url), file.body)
      end
    end
  end

  def to_contact
    Contact.new(id: id, ip: ip, port: port)
  end

  def receive_ping(contact)
    @routing_table.insert(contact)
  end

  def ping(contact)
    response = @network.ping(contact, to_contact)
    @routing_table.insert(contact) if response
    response
  end

  def store(file_id, address, recipient_contact)
    response = @network.store(file_id, address, recipient_contact, to_contact)
    @routing_table.insert(recipient_contact) if response && response.code == 200
  end

  def receive_store(file_id, address, sender_contact)
    if @dht_segment[file_id]
      @dht_segment[file_id].push(address) unless @dht_segment[file_id].include?(address)
    else
      @dht_segment[file_id] = [address]
    end

    @routing_table.insert(sender_contact)
  end

  def iterative_store(file_id, address)
    results = iterative_find_node(file_id)

    results.each do |contact|
      store(file_id, address, contact)
    end
  end

  def receive_find_node(query_id, sender_contact)
    closest_contacts = @routing_table.find_closest_contacts(query_id, sender_contact)
    @routing_table.insert(sender_contact)
    closest_contacts
  end

  def find_node(query_id, recipient_contact)
    results = @network.find_node(query_id, recipient_contact, to_contact)
    results.each do |r|
      @routing_table.insert(r)
    end
    results
  end

  def iterative_find_node(query_id)
    shortlist = []
    results = @routing_table.find_closest_contacts(query_id, nil, Defaults::ENVIRONMENT[:alpha])

    until k_elements?(shortlist.select(&:active))
      fill_shortlist(shortlist, results)
      closest_contact = Binary.select_closest_xor(query_id, shortlist)

      # once we get past happy path, we only iterate over items not yet probed
      shortlist.each do |contact|
        temp_results = find_node(query_id, contact)
        ingest_contacts(temp_results, results, shortlist)
        contact.activate
      end

      break if results.empty? || closest_contact.nil? || no_closer_contacts(query_id, results, closest_contact)
    end
    shortlist
  end

  def receive_find_value(file_id, sender_contact)
    result = {}

    if dht_segment[file_id] && !dht_segment[file_id].empty?
      result['data'] = select_address(file_id)
    else
      result['contacts'] = receive_find_node(file_id, sender_contact)
    end
    @routing_table.insert(sender_contact)
    result
  end

  def select_address(file_id)
    values = dht_segment[file_id].clone.shuffle

    values.each do |address|
      response = @network.check_resource_status(address)
      if response == 200
        return address
      else
        evict_address(file_id, address)
      end
    end
    nil
  end

  def find_value(file_id, recipient_contact)
    results = @network.find_value(file_id, recipient_contact, to_contact)

    if results['contacts']
      results['contacts'].each do |r|
        @routing_table.insert(r)
      end
    end
    results
  end

  def iterative_find_value(query_id)
    shortlist = []
    results = @routing_table.find_closest_contacts(query_id, nil, Defaults::ENVIRONMENT[:alpha])

    until k_elements?(shortlist.select(&:active))
      fill_shortlist(shortlist, results)
      Binary.sort_by_xor!(id, shortlist)
      closest_contact = shortlist[0]

      # once we get past happy path, we only iterate over items not yet probed
      shortlist.each do |contact|
        temp_results = find_value(query_id, contact)
        if temp_results['data']
          store_at_second_closest(shortlist, contact, query_id, temp_results['data'])
          return temp_results['data']
        elsif temp_results['contacts']
          ingest_contacts(temp_results['contacts'], results, shortlist)
        end
        contact.activate
      end

      break if results.empty? || no_closer_contacts(query_id, results, closest_contact)
    end
    shortlist
  end

  def sync
    Storage.write_to_disk(self)
  end

  def buckets_refresh
    routing_table.buckets.each do |bucket|
      all_contacts = bucket.contacts
      size = all_contacts.size
      if size > 0
        contact_id = all_contacts[rand(size)].id
        iterative_find_node(contact_id)
      end
    end
  end

  def save_file(name, content)
    file_id = generate_file_id(content)
    file_name = Defaults::ENVIRONMENT[:files] + '/' + name
    write_to_subfolder(Defaults::ENVIRONMENT[:files], name, content)
    add_to_cache(@files, file_id, '/files/' + name)
    Thread.new { shard_file(file_name, file_id) }
  end

  private

  def add_manifest(obj, file_id)
    file_name = file_id + '.xro'
    file_path = '/manifests/' + file_name

    write_to_subfolder(Defaults::ENVIRONMENT[:manifests], file_name, obj)
    add_to_cache(@manifests, file_id, file_path)
    iterative_store(file_id, file_url(file_path))
  end

  def add_shard(name, data)
    file_path = '/shards/' + name

    write_to_subfolder(Defaults::ENVIRONMENT[:shards], name, data)
    add_to_cache(@shards, name, file_path)
    iterative_store(name, file_url(file_path))
  end

  def add_to_cache(cache, key, value)
    cache[key] = value
  end

  def create_manifest(file_name, file_size)
    { file_name: file_name, length: file_size, pieces: [] }
  end

  def k_elements?(array)
    array.size == Defaults::ENVIRONMENT[:k]
  end

  def ingest_contacts(source, dest, shortlist)
    source.each do |c|
      dest.push(c) if new_contact?(c, dest, shortlist)
    end
  end

  def new_contact?(contact, array1, array2)
    !array1.find { |obj| obj.id == contact.id } && !array2.find { |obj| obj.id == contact.id }
  end

  def evict_address(file_id, address)
    dht_segment[file_id].delete(address)
  end

  def file_url(filepath)
    "http://#{@ip}:#{@port}#{filepath}"
  end

  def fill_shortlist(shortlist, source)
    shortlist.push(source.pop.clone) until source.empty? || k_elements?(shortlist)
  end

  def generate_file_id(file_content)
    Binary.sha(file_content).hex.to_s
  end

  def generate_manifest_cache
    @manifests = {}

    Dir.glob(File.expand_path(Defaults::ENVIRONMENT[:manifests] + '/*')).select { |f| File.file?(f) }.each do |file|
      file_hash = File.basename(file, ".xro")
      @manifests[file_hash] = '/manifests/' + File.basename(file)
    end
  end

  def generate_shard_cache
    @shards = {}

    Dir.glob(File.expand_path(Defaults::ENVIRONMENT[:shards] + '/*')).select { |f| File.file?(f) }.each do |file|
      file_hash = File.basename(file)
      @shards[file_hash] = '/shards/' + File.basename(file)
    end
  end

  def join(network)
    network.nodes.push(self)
  end

  def set_ip(port)
    @ip = lookup_ip(port)
  end

  def lookup_ip(port)
    if ENV['FQDN']
      ENV['FQDN']
    elsif ENV['WAN'] == 'true'
      ngrok = initialize_ngrok(port)
      File.basename(ngrok)
    else
      private_ip = Socket.ip_address_list.detect(&:ipv4_private?)
      private_ip ? private_ip.ip_address : 'localhost'
    end
  end

  def initialize_ngrok(port)
    authfile = ENV['HOME'] + "/.ngrok2/ngrok.yml"
    if File.exist?(authfile)
      authtoken = authfile["authtoken"]
      ngrok = Ngrok::Tunnel.start(port: port, authtoken: authtoken)
    else
      ngrok = Ngrok::Tunnel.start(port: port)
    end
  end

  def no_closer_contacts(query_id, results, closest_contact)
    Binary.xor_distance_map(query_id, results).min >= Binary.xor_distance(closest_contact.id, query_id)
  end

  def reassemble_shards(shards, manifest)
    shard_paths = shards.map do |shard|
      Defaults::ENVIRONMENT[:shards] + '/' + shard
    end

    File.open(Defaults::ENVIRONMENT[:files] + '/' + manifest['file_name'], 'a') do |f|
      shard_paths.each do |path|
        f.write(File.read(path))
      end
    end
  end

  def compile_shards(manifest_body, manifest_name)
    manifest = JSON.parse(manifest_body)
    shards_ids = manifest['pieces']
    shard_count = shards_ids.length

    shards_ids.each do |shard_id|
      fetch_shard(shard_id) unless shard_exist?(shard_id)
      shard_count -= 1 if valid_shard?(shard_id)
    end

    if shard_count.zero?
      reassemble_shards(shards_ids, manifest)
      add_to_cache(@files, File.basename(manifest_name, '.xro'), '/files/' + manifest['file_name'])
    end
    sync
  end

  def shard_exist?(shard)
    File.exist?(Defaults::ENVIRONMENT[:shards] + '/' + shard)
  end

  def shard_file(file, id)
    size = File.stat(file).size
    manifest = create_manifest(File.basename(file), size)
    shard_size = size <= 1048576 ? size / 2 : 1048576

    File.open(file, "r") do |fh_in|
      until fh_in.eof?
        piece = fh_in.read(shard_size)
        piece_hash = generate_file_id(piece)

        manifest[:pieces].push(piece_hash)
        add_shard(piece_hash, piece) unless @shards[piece_hash]
      end
    end

    add_manifest(manifest.to_json, id)
    sync
  end

  def store_at_second_closest(shortlist, contact, query_id, data)
    second_closest = shortlist.find { |c| c.id != contact.id }
    store(query_id, data, second_closest) if second_closest
  end

  def valid_shard?(shard)
    shard_content = File.read(Defaults::ENVIRONMENT[:shards] + '/' + shard)
    generate_file_id(shard_content) == shard
  end

  def fetch_shard(shard)
    result = iterative_find_value(shard)
    get(result) if result
  end

  def write_to_subfolder(destination, name, content)
    file_name = destination + '/' + name
    File.open(file_name, 'wb') do |f|
      f.write(content)
    end
  end
end
