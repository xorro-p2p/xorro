require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/multi_route'
require 'sinatra/flash'
require 'ngrok/tunnel'
require 'json'
require 'erubis'
require 'thin'
require 'yaml'
require 'concurrent'
require_relative 'lib/defaults.rb'
require_relative 'lib/node.rb'
require_relative 'lib/network_adapter.rb'
require_relative 'lib/contact.rb'
require_relative 'lib/defaults.rb'
require_relative 'lib/storage.rb'


class XorroNode < Sinatra::Base
  register Sinatra::MultiRoute
  register Sinatra::Flash
  register Sinatra::ConfigFile
  config_file 'config.yml'

  set :bind, '0.0.0.0'
  enable :sessions

  network = NetworkAdapter.instance

  Defaults.setup(settings.port, settings.node_homes)

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

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      creds = [settings.username, settings.password]
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == creds
    end
  end

  ### RPC Routes

  get '/rpc/info' do
    NODE.to_contact.to_json
  end

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

  ### UI ROUTES

  get '/upload_file' do
    protected!
    @title = "Upload File"
    @node = NODE
    erb :upload_file
  end

  get '/get_file' do
    protected!
    @title = "Get File"
    @node = NODE
    erb :get_file
  end

  get '/', '/my_files' do
    protected!
    @title = "My Files"
    @refresh = '<meta http-equiv="refresh" content="5">'
    @node = NODE
    @superport = @node.superport || 'none'
    erb :my_files
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

  post '/upload_file' do
    start = params[:data].index(',') + 1
    file_data = params[:data][start..-1]
    decode_base64_content = Base64.decode64(file_data)
    NODE.save_file(params[:name], decode_base64_content)
    status 200
  end

  # debugging rpc control methods.
  get '/debug/node_info' do
    protected!
    @title = "Node Information"
    @node = NODE
    @superport = @node.superport || 'none'
    erb :node_info
  end

  get '/debug/data' do
    protected!
    @title = "Data Cache"
    @node = NODE
    @superport = @node.superport || 'none'
    erb :data
  end

  get '/debug/routing_table' do
    protected!
    @title = "Routing Table"
    @node = NODE
    @superport = @node.superport || 'none'
    erb :routing_table
  end

  get '/debug/dht' do
    protected!
    @title = "DHT Segment"
    @node = NODE
    @superport = @node.superport || 'none'
    erb :dht
  end
  get '/debug/rpc' do
    protected!
    @title = "RPC Debugging"
    @node = NODE
    @superport = @node.superport || 'none'
    erb :rpc
  end

  # these initiate an rpc call from the current node to other nodes
  post '/debug/rpc/send_find_node' do
    query_id = params[:query_id]
    @result = NODE.iterative_find_node(query_id)
    @node = NODE
    erb :test
  end

  post '/debug/rpc/send_find_value' do
    query_id = params[:file_id]
    @result = NODE.iterative_find_value(query_id)
    @node = NODE
    erb :test
  end

  post '/debug/rpc/send_rpc_store' do
    key = params[:key]
    data = params[:data]

    contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port])
    NODE.store(key, data, contact)
    redirect '/debug/rpc'
  end

  post '/debug/rpc/send_it_store' do
    key = params[:key]
    data = params[:data]
    NODE.iterative_store(key, data)

    redirect '/debug/rpc'
  end

  post '/debug/rpc/send_rpc_ping' do
    contact = Contact.new(id: params[:id], ip: params[:ip], port: params[:port].to_i)
    NODE.ping(contact)
    redirect '/debug/rpc'
  end

  run! if app_file == $0
end
