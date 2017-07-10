require 'webrick'
require_relative 'development.rb'

### ENV['uploads'] = "~/path/to/uploads/folder"

root = File.expand_path ENV['uploads']
server = WEBrick::HTTPServer.new :Port => 8000, :DocumentRoot => root
server.start