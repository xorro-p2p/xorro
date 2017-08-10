require 'http'
require_relative 'contact.rb'

class NetworkAdapter
  attr_reader :nodes
  include Singleton

  def initialize
    @nodes = []
  end

  def store(file_id, address, recipient_contact, sender_contact)
    info_hash = hashify(sender_contact, file_id: file_id, address: address)
    begin
      response = call_rpc(recipient_contact, 'store', info_hash)
    rescue
      response = false
    end
    response
  end

  def find_node(query_id, recipient_contact, sender_contact)
    info_hash = hashify(sender_contact, node_id: query_id)
    begin
      response = call_rpc(recipient_contact, 'find_node', info_hash)
      closest_nodes = JSON.parse(response)
    rescue
      closest_nodes = []
    end
    contactify!(closest_nodes)
  end

  def find_value(file_id, recipient_contact, sender_contact)
    info_hash = hashify(sender_contact, file_id: file_id)
    begin
      response = call_rpc(recipient_contact, 'find_value', info_hash)
      result = JSON.parse(response)
    rescue
      result = {}
    end
    if result['contacts']
      contactify!(result['contacts'])
    end
    result
  end

  def ping(recipient_contact, sender_contact)
    info_hash = hashify(sender_contact)
    begin
      response = call_rpc(recipient_contact, 'ping', info_hash)
    rescue
      return false
    end
    response.code == 200
  end

  def info(url, port)
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

  public_class_method :allocate

  private

  def contactify!(array)
    array.map! do |contact|
      Contact.new(id: contact['id'], ip: contact['ip'], port: contact['port'].to_i)
    end
  end

  def hashify(sender, options = {})
    { id: sender.id,
      ip: sender.ip,
      port: sender.port }.merge(options)
  end

  def call_rpc(recipient_contact, path, info_hash)
    url = recipient_contact.ip
    port = recipient_contact.port
    HTTP.post('http://' + url + ':' + port.to_s + "/rpc/#{path}", form: info_hash)
  end

  def call_get_info(url, port)
    HTTP.get('http://' + url + ':' + port.to_s + '/rpc/info')
  end
end
