require 'open-uri'
require 'digest/sha1'
require_relative 'development.rb'
require_relative 'binary.rb'
require_relative 'routing_table.rb'
require_relative 'contact.rb'
require_relative 'network_adapter.rb'


class Node
  attr_accessor :ip, :id, :files, :routing_table, :dht_segment
  def initialize(num_string, network)
    @ip = lookup_ip
    @network = network
    join(@network)
    # @id = Binary.sha(num_string) # TEMP - using a fixed string for now to generate ID hash
    @id = num_string
    @routing_table = RoutingTable.new(self)
    @files = generate_file_cache
    @dht_segment = {}
  end

  def join(network)
    network.nodes.push(self)
  end

  def lookup_ip
    open('http://whatismyip.akamai.com').read
  end

  def generate_file_cache
    cache = {}

    Dir.glob(File.expand_path(ENV['uploads'] + '/*')).select { |f| File.file?(f) }.each do |file|
      file_hash = Binary.sha(File.basename(file))
      cache[file_hash] = file
    end
    cache
  end

  def to_contact
    Contact.new({:id => id, :ip => ip})
  end

  def receive_ping(contact)
    @routing_table.insert(contact)
  end

  def ping(contact)
    recipient_node = @network.get_node_by_contact(contact)

    if recipient_node
      recipient_node.receive_ping(self.to_contact)
      contact.update_last_seen
      @routing_table.insert(contact)
    end 

    recipient_node
  end

  def store(file_id, address, recipient_contact)
    recipient_node = @network.get_node_by_contact(recipient_contact)
    recipient_node.receive_store(file_id, address, to_contact)
    ping(recipient_contact)
  end

  def receive_store(file_id, address, contact)
    @dht_segment[file_id] = address
    ping(contact)
  end

  def receive_find_node(id, contact)
    # i received an ID
    # i want my routing table to return an array of k contacts
    # i give the requester the array
    results = @routing_table.find_closest_contacts(id)
  end

  def find_node()
    # i'm telling another node to receive_find_nodes
    # i get an array of k contacts

  end
end
