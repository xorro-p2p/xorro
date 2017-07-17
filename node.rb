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

  def receive_store(file_id, address, sender_contact)
    @dht_segment[file_id] = address
    ping(sender_contact)
  end

  def receive_find_node(query_id, sender_contact)
    # i received an ID
    # i want my routing table to return an array of k contacts
    # i give the requester the array
    # have to exclude the requestor contact

    closest_nodes = @routing_table.find_closest_contacts(query_id, sender_contact)
    ping(sender_contact)

    closest_nodes
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

    recipient_node = @network.get_node_by_contact(recipient_contact)
    closest_nodes = recipient_node.receive_find_node(query_id, self.to_contact)
    ping(recipient_contact)

    closest_nodes
  end

  def receive_find_value(file_id, sender_contact)
    result = {}

    if dht_segment[file_id]
      result['data'] = dht_segment[file_id]
    else
      result['contacts'] = receive_find_node(file_id, sender_contact)
    end

    ping(sender_contact)
    result
  end

  def find_value(file_id, recipient_contact)
    recipient_node = @network.get_node_by_contact(recipient_contact)
    result = recipient_node.receive_find_value(file_id, self.to_contact)
  end
end
