require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/multi_route'
require 'json'
require 'erubis'
require 'pry'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'lib/node.rb'
require_relative 'lib/network_adapter.rb'
require_relative 'lib/contact.rb'
require_relative 'lib/defaults.rb'


NETWORK = NetworkAdapter.new

Defaults.setup(settings.port)
id_file = YAML::load_file(File.join(ENV['home'], "/id.yml"))

NODE = Node.new(id_file[:id], NETWORK, settings.port)

get '/', '/debug/node' do
  @title = "Node Info"
  @node = NODE
  erb :node
end

get '/debug/buckets' do
  @title = "K-Buckets"
  @node = NODE
  erb :buckets
end

get '/', '/debug/dht' do
  @title = "DHT Segment"
  @node = NODE
  erb :dht
end

get '/files/:filename' do
  send_file File.join(File.expand_path(ENV['uploads']) , params[:filename])
end

post '/rpc/store' do
  file_id = params[:file_id]
  address = params[:address]
  contact = Contact.new({id: params[:id], ip: params[:ip], port: params[:port].to_i})
  NODE.receive_store(file_id, address, contact)
end

post '/rpc/find_node' do
  node_id = params[:node_id]
  contact = Contact.new({id: params[:id], ip: params[:ip], port: params[:port].to_i})
  result = NODE.receive_find_node(node_id, contact)
  result.to_json
end

post '/rpc/find_value' do
  file_id = params[:file_id]
  contact = Contact.new({id: params[:id], ip: params[:ip], port: params[:port].to_i})
  result = NODE.receive_find_value(file_id, contact)
  result.to_json
end

post '/rpc/ping' do
  contact = Contact.new({id: params[:id], ip: params[:ip], port: params[:port].to_i})
  NODE.receive_ping(contact)
  status 200
end


