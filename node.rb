require 'open-uri'
require 'digest/sha1'
require_relative 'development.rb'
require_relative 'binary.rb'
require_relative 'routing_table.rb'
require_relative 'contact.rb'
require_relative 'kademlia_network.rb'


class Node
  attr_accessor :ip, :id, :files, :routing_table
  def initialize(num_string, network)
    @ip = lookup_ip
    @network = network
    join(@network)
    # @id = Binary.sha(num_string) # TEMP - using a fixed string for now to generate ID hash
    @id = num_string
    @routing_table = RoutingTable.new(@id)
    @files = generate_file_cache
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

  def ping(recipient_id)
    recipient_node = @network.nodes.find {|n| n.id == recipient_id }

    if recipient_node
      recipient_node.receive_ping(self.to_contact)
      @routing_table.insert(recipient_node.to_contact)
    end 

    recipient_node
  end
end
