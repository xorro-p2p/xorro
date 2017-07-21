require 'sinatra'
require 'sinatra/reloader'
require 'erubis'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'lib/node.rb'
require_relative 'lib/network_adapter.rb'
require 'json'
require 'pry'
require_relative 'lib/contact.rb'


NETWORK = NetworkAdapter.new
NODE = Node.new('3', NETWORK)

set :static, true
set :public_folder, File.expand_path(ENV['uploads'])


get '/debug/dht' do
  @dht = NODE.dht_segment.to_json
  erb :dht
end

get '/debug/buckets' do
  @buckets = NODE.routing_table.buckets
  erb :buckets
end

post '/rpc/store' do
  file_id = params[:file_id]
  address = params[:address]
  contact = Contact.new({id: params[:id], ip: params[:ip], port: params[:port].to_i})
  NODE.receive_store(file_id, address, contact)
end

post '/rpc/find_node' do
  # ## store rpc
  # sender_contact = params[:sender_contact]
  # file_id = params[:file_id]
  # address = params[:address]
  # fake_hash = {id: '32', ip: '10.10.10.10', port: '3339'}

  # NODE.receive_store(file_id, address, Contact.new({id: '32', ip: '10.10.10.10', port: '3339'}))
  # NODE.dht_segment.to_s
  # sender_contact
end

post '/rpc/find_value' do
  # sender_contact = params[:sender_contact]
  # file_id = params[:file_id]
  # address = params[:address]
  # fake_hash = {id: '32', ip: '10.10.10.10', port: '3339'}

  # NODE.receive_store(file_id, address, Contact.new({id: '32', ip: '10.10.10.10', port: '3339'}))
  # NODE.dht_segment.to_s
  # sender_contact
end

