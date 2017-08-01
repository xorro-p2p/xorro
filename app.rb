require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/multi_route'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'ngrok/tunnel'
require 'json'
require 'erubis'
require 'pry'
require 'thin'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'lib/node.rb'
require_relative 'lib/network_adapter.rb'
require_relative 'lib/contact.rb'
require_relative 'lib/defaults.rb'
require_relative 'lib/storage.rb'

## must be used for app to server on IP other than localhost
set :bind, '0.0.0.0'

enable :sessions

NETWORK = NetworkAdapter.new
Defaults.setup(settings.port)

if ENV['WAN'] == 'true'
  NGROK = Ngrok::Tunnel.start(port: settings.port)
end

NODE = Defaults.create_node(NETWORK, settings.port)
NODE.activate

get '/', '/debug/node' do
   @title = "Node Info"
   @node = NODE
   @super = @node.is_super
   @superport = @node.superport || 'none'
   @wan_mode = ENV['WAN'] == 'true'
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

 get '/drop_zone' do
  @node = NODE
  erb :drop_zone
 end

 get '/get_file' do
  @node = NODE
  erb :get_file
 end


get '/files/:filename' do
  send_file File.join(File.expand_path(ENV['uploads']) , params[:filename])
end

### RPC Routes

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

post '/get_file' do
  query_id = params[:file_id]

  if NODE.files[query_id]
    redirect "/files/" + URI.escape(NODE.files[query_id])
  else
    if NODE.dht_segment[query_id]
      result = NODE.select_address(query_id)
    end

    if result.nil?
      result = NODE.iterative_find_value(query_id)
    end

    if result && result.is_a?(String)
      NODE.get(result)
      redirect "/files/" + URI.escape(File.basename(result))
    else
      @node = NODE
      flash[:notice] = "Your file could not be found."
      redirect "/get_file"
    end
  end
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

post '/save_to_uploads' do
  start = params[:data].index(',') + 1
  file_data = params[:data][start..-1]
  decode_base64_content = Base64.decode64(file_data)
  file_name = ENV['uploads'] + '/' + params[:name]
  
  NODE.write_to_uploads(params[:name], decode_base64_content)
  NODE.add_file(decode_base64_content, params[:name])
  
  status 200
end

######  IMPORTANT - THIS IS REQUIRED, AS BOTH SINATRA AND NGROK HAVE CONFLICTING EXIT HOOKS
##### MANUALLY STARTING SINATRA HERE IS A WORKAROUND
Sinatra::Application.run!


