require 'http'

class NetworkAdapter
  attr_accessor :nodes
  
  def initialize
    @nodes = []
  end

  def get_node_by_contact(contact)
    @nodes.find {|n| n.id == contact.id }
  end

  def store(file_id, address, recipient_contact, sender_contact)
    if ENV['development'] == 'true'
      recipient_node = get_node_by_contact(recipient_contact)
      recipient_node.receive_store(file_id, address, sender_contact)
      node = get_node_by_contact(sender_contact)
      node.ping(recipient_contact)
      # ping(recipient_contact)
    else
      info_hash = {:file_id => file_id, :address => address, :port => sender_contact.port, :id => sender_contact.id, :ip => sender_contact.ip }
      url = recipient_contact.ip
      port = recipient_contact.port
      call_rpc_store(url, port, info_hash)
      
      response
    end
  end

  def find_node(query_id, recipient_contact, sender_contact)
    if ENV['development'] == 'true'
      recipient_node = get_node_by_contact(recipient_contact)
      closest_nodes = recipient_node.receive_find_node(query_id, sender_contact)
      node = get_node_by_contact(sender_contact)
      node.ping(recipient_contact)

      closest_nodes
    else
      info_hash = {:node_id => query_id, :id => sender_contact.id, :port => sender_contact.port}
      response = call_rpc_find_node(recipient_contact.ip, recipient_contact.port, info_hash)
      closest_nodes = JSON.parse(response)      
      closest_nodes.map! { |contact| Contact.new({ id: contact['id'], ip: contact['ip'], port: contact['port'].to_i }) }
    end
  end

  def find_value(file_id, recipient_contact, sender_contact)
    if ENV['development'] == 'true'
      recipient_node = get_node_by_contact(recipient_contact)
      node = get_node_by_contact(sender_contact)
      node.ping(recipient_contact)
      result = recipient_node.receive_find_value(file_id, sender_contact)
    else
      info_hash = {:file_id => file_id, :id => sender_contact.id, :port => sender_contact.port}
      response = call_rpc_find_value(recipient_contact.ip, recipient_contact.port, info_hash)
      result = JSON.parse(response)

      # closest_node['contacts']
      # closest_node['data']

    end
  end

  def call_rpc_store(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/store', :form => info_hash)
  end


  def call_rpc_find_node(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/find_node', :form => info_hash)
  end

  def call_rpc_find_value(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/find_value', :form => info_hash)
  end
end



