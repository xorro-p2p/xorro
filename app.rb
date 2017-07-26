require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/multi_route'
require 'sinatra/content_for'
require 'json'
require 'erubis'
require 'pry'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'lib/node.rb'
require_relative 'lib/network_adapter.rb'
require_relative 'lib/contact.rb'
require_relative 'lib/defaults.rb'
require_relative 'lib/storage.rb'


NETWORK = NetworkAdapter.new

Defaults.setup(settings.port)

NODE = Defaults.create_node(NETWORK, settings.port)
NODE.activate

get '/', '/debug/node' do
   @title = "Node Info"
   @node = NODE
   @super = @node.is_super
   @superport = @node.superport || 'none'
   erb :node
 end
 
 get '/debug/buckets' do
   @title = "K-Buckets"
   @node = NODE
   @super = @node.is_super
   @superport = @node.superport || 'none'
   erb :buckets
 end
 
 get '/', '/debug/dht' do
   @title = "DHT Segment"
   @node = NODE
   @super = @node.is_super
   @superport = @node.superport || 'none'
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
  status 200
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

post '/send_find_node' do
  query_id = params[:query_id]
  
  @result = NODE.iterative_find_node(query_id)
  
  @node = NODE
  erb :test
  # redirect '/'
end

get '/info' do
  NODE.to_contact.to_json
end

post '/send_find_value' do
  query_id = params[:file_id]
  
  @result = NODE.iterative_find_value(query_id)
  
  @node = NODE
  erb :test
  # redirect '/'
end

post '/send_rpc_store' do
  key = params[:key]
  data = params[:data]

  contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port])
  NODE.store(key, data, contact)
  redirect '/'
end

post '/send_it_store' do
  key = params[:key]
  data = params[:data]
  NODE.iterative_store(key, data)

  redirect '/'
end

post '/send_rpc_ping' do
  id = params[:id]
  ip = params[:ip]
  port = params[:port]
  contact = Contact.new({id: params[:id], ip: params[:ip], port: params[:port].to_i})
  NODE.ping(contact)
  redirect '/'
end


