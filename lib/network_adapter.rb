require 'http'
require_relative 'contact.rb'

class NetworkAdapter
  attr_reader :nodes
  def initialize
    @nodes = []
  end

  def store(file_id, address, recipient_contact, sender_contact)
    info_hash = { file_id: file_id, address: address, port: sender_contact.port, id: sender_contact.id, ip: sender_contact.ip }
    url = recipient_contact.ip
    port = recipient_contact.port
    begin
      response = call_rpc_store(url, port, info_hash)
    rescue
      response = false
    end
    response
  end

  def find_node(query_id, recipient_contact, sender_contact)
    info_hash = { node_id: query_id, id: sender_contact.id, ip: sender_contact.ip, port: sender_contact.port }
    begin
      response = call_rpc_find_node(recipient_contact.ip, recipient_contact.port, info_hash)
      closest_nodes = JSON.parse(response)
    rescue
      closest_nodes = []
    end
    closest_nodes.map! { |contact| Contact.new(id: contact['id'], ip: contact['ip'], port: contact['port'].to_i) }
  end

  def find_value(file_id, recipient_contact, sender_contact)
    info_hash = { file_id: file_id, id: sender_contact.id, ip: sender_contact.ip, port: sender_contact.port }
    begin
      response = call_rpc_find_value(recipient_contact.ip, recipient_contact.port, info_hash)
      result = JSON.parse(response)
    rescue
      result = {}
    end
    if result['contacts']
      result['contacts'].map! { |contact| Contact.new(id: contact['id'], ip: contact['ip'], port: contact['port'].to_i) }
    end
    result
  end

  def ping(contact, sender_contact)
    info_hash = { port: sender_contact.port, id: sender_contact.id, ip: sender_contact.ip }
    begin
      response = call_rpc_ping(contact.ip, contact.port, info_hash)
    rescue
      return false
    end
    response.code == 200
  end

  def get_info(url, port)
    begin
      response = call_get_info(url, port)
    rescue
      response = '{}'
    end
    response
  end

  def get(url)
    begin
      response = HTTP.get(url)
    rescue
      response = false
    end
    response
  end

  def check_resource_status(url)
    begin
      response = HTTP.head(url).code
    rescue
      response = false
    end
    response
  end

  private

  def call_rpc_ping(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/ping', form: info_hash)
  end

  def call_rpc_store(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/store', form: info_hash)
  end

  def call_rpc_find_node(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/find_node', form: info_hash)
  end

  def call_rpc_find_value(url, port, info_hash)
    HTTP.post('http://' + url + ':' + port.to_s + '/rpc/find_value', form: info_hash)
  end

  def call_get_info(url, port)
    HTTP.get('http://' + url + ':' + port.to_s + '/info')
  end
end
