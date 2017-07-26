require 'open-uri'
require 'digest/sha1'
require_relative '../development.rb'
require_relative 'binary.rb'
require_relative 'routing_table.rb'
require_relative 'contact.rb'
require_relative 'network_adapter.rb'
require_relative 'storage.rb'
require 'pry'


class Node
  attr_accessor :ip, :id, :port, :files, :routing_table, :dht_segment, :is_super
  def initialize(num_string, network, port='80', is_super=false)
    @ip = lookup_ip
    @network = network
    @port = port
    join(@network)
    # @id = Binary.sha(num_string) # TEMP - using a fixed string for now to generate ID hash
    @id = num_string
    @routing_table = RoutingTable.new(self)
    generate_file_cache
    @dht_segment = {}
    @is_super = false
  end

  def promote
    @is_super = true
  end

  def join(network)
    network.nodes.push(self)
    sync
  end

  def lookup_ip
    'localhost'
    #open('http://whatismyip.akamai.com').read
  end

  def generate_file_cache
    cache = {}

    Dir.glob(File.expand_path(ENV['uploads'] + '/*')).select { |f| File.file?(f) }.each do |file|
      file_hash = Binary.sha(File.basename(file))
      cache[file_hash] = File.basename(file)
    end
    @files = cache
    sync
  end
  
  def to_contact
    Contact.new({:id => id, :ip => ip, :port => port })
  end

  def receive_ping(contact)
    @routing_table.insert(contact)
  end

  def ping(contact)
    response = @network.ping(contact, to_contact)
    # recipient_node = @network.get_node_by_contact(contact)

    # if recipient_node
    #   recipient_node.receive_ping(self.to_contact)
    #   contact.update_last_seen
    #   @routing_table.insert(contact)
    # end 
    @routing_table.insert(contact) if response
    response
  end

  def store(file_id, address, recipient_contact)
    response = @network.store(file_id, address, recipient_contact, self.to_contact)
    @routing_table.insert(recipient_contact) if response && response.code == 200
  end

  def receive_store(file_id, address, sender_contact)
    @dht_segment[file_id] = address
    @routing_table.insert(sender_contact)
    # ping(sender_contact)
  end

  def iterative_store(file_id, address)
    results = iterative_find_node(file_id)

    results.each do |contact|
      store(file_id, address, contact)
    end
  end

  def receive_find_node(query_id, sender_contact)
    # i received an ID
    # i want my routing table to return an array of k contacts
    # i give the requester the array
    # have to exclude the requestor contact

    closest_contacts = @routing_table.find_closest_contacts(query_id, sender_contact)
    # ping(sender_contact)
    @routing_table.insert(sender_contact)
    closest_contacts
  end

  def find_node(query_id, recipient_contact)
    # i'm telling another node to receive_find_nodes
    # i get an array of k contacts
    # The name of this RPC is misleading. Even if the key to the RPC is the nodeID of an
    # existing contact or indeed if it is the nodeID of the recipient itself, the recipient
    # is still required to return k triples. A more descriptive name would be FIND_CLOSE_NODES. 

    # The recipient of a FIND_NODE should never return a triple containing the nodeID of the requestor.
    # If the requestor does receive such a triple, it should discard it.
    # A node must never put its own nodeID into a bucket as a contact.

    @network.find_node(query_id, recipient_contact, self.to_contact)
  end

  #### refactor this method to accept indeterminate list of array arguments, move to utility module
  def contact_is_not_in_results_or_shortlist(contact, array1, array2)
    !array1.find { |obj| obj.id == contact.id } && !array2.find { |obj| obj.id == contact.id }
  end

  def iterative_find_node(query_id)
    shortlist = []
    results_returned = @routing_table.find_closest_contacts(query_id, nil, ENV['alpha'].to_i)

    until shortlist.select(&:active).size == ENV['k'].to_i
      shortlist.push(results_returned.pop.clone) until results_returned.empty? || shortlist.size == ENV['k'].to_i
      closest_contact = Binary.select_closest_xor(query_id, shortlist)

      # once we get past happy path, we only iterate over items not yet probed
      shortlist.each do |contact|
        temp_results = find_node(query_id, contact)
        temp_results.each do |t|
          results_returned.push(t) if contact_is_not_in_results_or_shortlist(t, results_returned, shortlist)
        end
        #happy path only.. contact will be marked as probed when queried, then marked as active if we receive a reply
        #contact stays in probed mode until reply is received.
        contact.active = true
      end

      break if results_returned.empty? || 
               Binary.xor_distance_map(query_id, results_returned).min >= Binary.xor_distance(closest_contact.id, query_id)
    end

    return shortlist
  end

  def receive_find_value(file_id, sender_contact)
    result = {}

    if dht_segment[file_id]
      result['data'] = dht_segment[file_id]
    else
      result['contacts'] = receive_find_node(file_id, sender_contact)
    end
    @routing_table.insert(sender_contact)
    # ping(sender_contact)
    result
  end

  def find_value(file_id, recipient_contact)
    @network.find_value(file_id, recipient_contact, self.to_contact)
  end

  def iterative_find_value(query_id)
    return dht_segment[query_id] if dht_segment[query_id]

    shortlist = []
    results_returned = @routing_table.find_closest_contacts(query_id, nil, ENV['alpha'].to_i)

    until shortlist.select(&:active).size == ENV['k'].to_i
      shortlist.push(results_returned.pop.clone) until results_returned.empty? || shortlist.size == ENV['k'].to_i
      # closest_contact = Binary.select_closest_xor(query_id, shortlist)
      Binary.sort_by_xor!(id, shortlist)
      closest_contact = shortlist[0]

      # once we get past happy path, we only iterate over items not yet probed
      shortlist.each do |contact|
        temp_results = find_value(query_id, contact)

        if temp_results['data']
          # When this function succeeds (finds the value), a STORE RPC is sent to
          # the closest Contact which did not return the value.
          second_closest = shortlist.find { |c| c.id != contact.id }
          store(query_id, temp_results['data'], second_closest) if second_closest
 
          return temp_results['data']
        end

        if temp_results['contacts']
          temp_results['contacts'].each do |t|
            results_returned.push(t) if contact_is_not_in_results_or_shortlist(t, results_returned, shortlist)
          end
        end
        #happy path only.. contact will be marked as probed when queried, then marked as active if we receive a reply
        #contact stays in probed mode until reply is received.
        contact.active = true
      end

      break if results_returned.empty? || 
               Binary.xor_distance_map(query_id, results_returned).min >= Binary.xor_distance(closest_contact.id, query_id)
    end

    return shortlist
  end

  def sync
    Storage.write_to_disk(self)
  end
end
