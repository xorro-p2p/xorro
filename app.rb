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
require_relative 'lib/storage.rb'


NETWORK = NetworkAdapter.new

Defaults.setup(settings.port)

NODE = Defaults.create_node(NETWORK, settings.port)

get '/', '/debug/node' do
   @title = "Node Info"
   @super = ENV['SUPER'] || 'false'
   @node = NODE
   @superport = ENV['SUPERPORT'] || 'none'
   erb :node
 end
 
 get '/debug/buckets' do
   @title = "K-Buckets"
   @super = ENV['SUPER'] || 'false'
   @superport = ENV['SUPERPORT'] || 'none'
   @node = NODE
   erb :buckets
 end
 
 get '/', '/debug/dht' do
   @title = "DHT Segment"
   @super = ENV['SUPER'] || 'false'
   @superport = ENV['SUPERPORT'] || 'none'
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

post '/send_find_node' do
  query_id = params[:query_id]
  
  @contacts = NODE.iterative_find_node(query_id)
  
  @node = NODE
  erb :test
  # redirect '/'
end

post '/send_find_value' do
  query_id = params[:file_id]
  
  @contacts = NODE.iterative_find_value(query_id)
  
  @node = NODE
  erb :test
  # redirect '/'
end

post '/send_store' do
  key = params[:key]
  data = params[:data]
  NODE.iterate_store(key, data)

  redirect '/'
end


