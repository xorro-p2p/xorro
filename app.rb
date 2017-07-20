require 'sinatra'
require 'sinatra/reloader'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'node.rb'
require_relative 'network_adapter.rb'
require 'json'
require 'pry'
require_relative 'contact'

NETWORK = NetworkAdapter.new
NODE = Node.new('3', NETWORK)

set :static, true
set :public_folder, File.expand_path(ENV['uploads'])

post '/rpc' do
  ## store rpc
  command = params[:command]
  sender_contact = params[:sender_contact]
  file_id = params[:file_id]
  address = params[:address]
  fake_hash = {id: '32', ip: '10.10.10.10', port: '3339'}

  NODE.receive_store(file_id, address, Contact.new({id: '32', ip: '10.10.10.10', port: '3339'}))
  NODE.dht_segment.to_s
  sender_contact
end

