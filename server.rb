require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'node.rb'
require 'pry'


set :static, true
# set :public_folder, File.expand_path(ENV['uploads'])
set :node, Node.new

get '/' do
  
  erb :home
end

get '/uploads' do
  @node = settings.node
  erb :uploads
end

