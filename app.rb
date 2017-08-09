require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/multi_route'
require 'sinatra/flash'
require 'ngrok/tunnel'
require 'json'
require 'erubis'
require 'thin'
require 'yaml'
require 'concurrent'
require_relative 'config.rb'
require_relative 'lib/defaults.rb'
require_relative 'lib/node.rb'
require_relative 'lib/network_adapter.rb'
require_relative 'lib/contact.rb'
require_relative 'lib/defaults.rb'
require_relative 'lib/storage.rb'

class XorroNode < Sinatra::Base
  register Sinatra::MultiRoute
  register Sinatra::Flash

  set :bind, '0.0.0.0'
  enable :sessions

  network = NetworkAdapter.instance
  Defaults.setup(settings.port)

  NODE = Defaults.create_node(network, ENV['WAN'] == 'true' ? 80 : settings.port)
  NODE.activate(settings.port)

  refresh_task = Concurrent::TimerTask.new(execution_interval: 3600, timeout_interval: 3600) do
    NODE.buckets_refresh
  end
  refresh_task.execute

  rebroadcast_task = Concurrent::TimerTask.new(execution_interval: 4200, timeout_interval: 4200) do
    NODE.broadcast
  end
  rebroadcast_task.execute

  get '/', '/debug/node' do
    @title = "Node Info"
    @refresh = '<meta http-equiv="refresh" content="5">'
    @node = NODE
    @superport = @node.superport || 'none'
    erb :node
  end

  get '/debug/data' do
    @title = "Data"
    @node = NODE
    @superport = @node.superport || 'none'
    erb :data
  end

  get '/debug/buckets' do
    @title = "K-Buckets"
    @node = NODE
    @superport = @node.superport || 'none'
    erb :buckets
  end

  get '/debug/dht' do
    @title = "DHT Segment"
    @node = NODE
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

  post '/get_file' do
    query_id = params[:file_id]
    file_url = NODE.files[query_id]

    if file_url && File.exist?(Defaults::ENVIRONMENT[:files] + "/" + File.basename(file_url))
      redirect URI.escape(file_url)
    else
      result = nil

      if NODE.dht_segment[query_id]
        result = NODE.select_address(query_id)
      end

      if result.nil?
        result = NODE.iterative_find_value(query_id)
      end

      if result && result.is_a?(String)
        Thread.new { NODE.get(result) }
        flash[:notice] = "Your file should be downloaded shortly."
        redirect "/"
      else
        @node = NODE
        flash[:notice] = "Your file could not be found."
        redirect "/get_file"
      end
    end
  end

  get '/info' do
    NODE.to_contact.to_json
  end

  ### File retreival routes

  get '/files/:filename' do
    send_file File.join(File.expand_path(Defaults::ENVIRONMENT[:files]), params[:filename])
  end

  get '/manifests/:filename' do
    send_file File.join(File.expand_path(Defaults::ENVIRONMENT[:manifests]), params[:filename])
  end

  get '/shards/:filename' do
    send_file File.join(File.expand_path(Defaults::ENVIRONMENT[:shards]), params[:filename])
  end

  ### RPC Routes

  post '/rpc/store' do
    file_id = params[:file_id]
    address = params[:address]
    contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port].to_i)
    NODE.receive_store(file_id, address, contact)
    status 200
  end

  post '/rpc/find_node' do
    node_id = params[:node_id]
    contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port].to_i)
    result = NODE.receive_find_node(node_id, contact)
    result.to_json
  end

  post '/rpc/find_value' do
    file_id = params[:file_id]
    contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port].to_i)
    result = NODE.receive_find_value(file_id, contact)
    result.to_json
  end

  post '/rpc/ping' do
    contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port].to_i)
    NODE.receive_ping(contact)
    status 200
  end

  # debugging rpc control methods.
  # these initiate an rpc call from the current node to other nodes

  post '/send_find_node' do
    query_id = params[:query_id]
    @result = NODE.iterative_find_node(query_id)
    @node = NODE
    erb :test
  end

  post '/send_find_value' do
    query_id = params[:file_id]
    @result = NODE.iterative_find_value(query_id)
    @node = NODE
    erb :test
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
    contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port].to_i)
    NODE.ping(contact)
    redirect '/'
  end

  post '/save_to_files' do
    start = params[:data].index(',') + 1
    file_data = params[:data][start..-1]
    decode_base64_content = Base64.decode64(file_data)
    NODE.save_file(params[:name], decode_base64_content)
    status 200
  end

  run! if app_file == $0
end
