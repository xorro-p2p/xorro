require 'sinatra'
require_relative 'development.rb'  ## ENV['uploads'] = "~/Desktop"
require_relative 'node.rb'
require 'pry'


set :static, true
set :public_folder, File.expand_path(ENV['uploads'])

# binding.pry

