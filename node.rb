require 'open-uri'
require 'digest/sha1'
require_relative 'development.rb'
require_relative 'binary.rb'


class Node
  attr_accessor :ip, :id, :files
  def initialize(num_string)
    @ip = lookup_ip
    # @id = Binary.sha(num_string) # TEMP - using a fixed string for now to generate ID hash
    @id = num_string
    @files = generate_file_cache
  end

  def lookup_ip
    open('http://whatismyip.akamai.com').read
  end

  def generate_file_cache
    cache = {}

    Dir.glob(File.expand_path(ENV['uploads'] + '/*')).select { |f| File.file?(f) }.each do |file|
      file_hash = Binary.sha(File.basename(file))
      cache[file_hash] = file
    end
    cache
  end
end
