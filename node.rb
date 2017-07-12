require 'open-uri'
require 'digest/sha1'
require_relative 'development.rb'


class Node
  attr_accessor :ip, :id, :files
  def initialize(num_string)
    @ip = lookup_ip
    # @id = sha(num_string) # TEMP - using a fixed string for now to generate ID hash
    @id = num_string
    @k_buckets = {}
    @files = generate_file_cache
  end

  def lookup_ip
    open('http://whatismyip.akamai.com').read
  end

  def generate_file_cache
    cache = {}

    Dir.glob(File.expand_path(ENV['uploads'] + '/*')).select { |f| File.file?(f) }.each do |file|
      file_hash = sha(File.basename(file))
      cache[file_hash] = file
    end
    cache
  end

  def id_distance(other_node)
    # need to convert back after using hash(ip) as id
    #@id.hex ^ other_node.id.hex
    @id.to_i ^ other_node.id.to_i
  end

  private

  def sha(str)
    Digest::SHA1.hexdigest(str)
  end
end
