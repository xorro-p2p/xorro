require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/multi_route'
require 'erubis'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'lib/node.rb'
require_relative 'lib/network_adapter.rb'
require 'json'
require 'pry'
require_relative 'lib/contact.rb'


NETWORK = NetworkAdapter.new
id = rand(2 ** ENV['bit_length'].to_i).to_s
NODE = Node.new(id, NETWORK, settings.port)

get '/', '/debug/node' do
  @title = "Node Info"
  @node = NODE
  @port = @node.port
  erb :node
end

get '/debug/dht' do
  @dht = NODE.dht_segment
  @title = 'DHT Segment'
  erb :dht
end

get '/debug/kbuckets' do
  @title = "K-Buckets"
  @buckets = NODE.routing_table.buckets
  erb :kbuckets
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


