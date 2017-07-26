require 'http'
require_relative 'contact.rb'

class NetworkAdapter
  attr_accessor :nodes
  
  def initialize
    @nodes = []
  end

  def store(file_id, address, recipient_contact, sender_contact)
    info_hash = {:file_id => file_id, :address => address, :port => sender_contact.port, :id => sender_contact.id, :ip => sender_contact.ip }
    url = recipient_contact.ip
    port = recipient_contact.port
    response = call_rpc_store(url, port, info_hash)
    response
  end

  def find_node(query_id, recipient_contact, sender_contact)
    info_hash = {:node_id => query_id, :id => sender_contact.id, :port => sender_contact.port}
    response = call_rpc_find_node(recipient_contact.ip, recipient_contact.port, info_hash)
    closest_nodes = JSON.parse(response)      
    closest_nodes.map! { |contact| Contact.new({ id: contact['id'], ip: contact['ip'], port: contact['port'].to_i }) }
  end

  def find_value(file_id, recipient_contact, sender_contact)
    info_hash = {:file_id => file_id, :id => sender_contact.id, :port => sender_contact.port}
    response = call_rpc_find_value(recipient_contact.ip, recipient_contact.port, info_hash)
    result = JSON.parse(response)
    if result['contacts']
      result['contacts'].map! { |contact| Contact.new({ id: contact['id'], ip: contact['ip'], port: contact['port'].to_i }) }
    end
    result
    
    # closest_node['contacts']
    # closest_node['data']
  end

  def ping(contact, sender_contact)
    info_hash = {:port => sender_contact.port, :id => sender_contact.id, :ip => sender_contact.ip }
    response = call_rpc_ping(contact.ip, contact.port, info_hash)
    return response.code == 200
  end


  private 

  def call_rpc_ping(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/ping', :form => info_hash)
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



