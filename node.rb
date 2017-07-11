require 'open-uri'
require 'digest/sha1'
require 'pry'


class Node
  attr_accessor :ip, :id, :files
  def initialize
    @ip = lookup_ip
    @id = generate_id
    @k_buckets = {}
    @files = generate_file_cache
  end

  def lookup_ip
    open('http://whatismyip.akamai.com').read
  end

  def generate_id
    Digest::SHA1.hexdigest(ip)
  end

  def generate_file_cache
    # ENV['upload_folder'] = './uploads/*'
    cache = {}

    Dir[ENV['upload_folder']].select { |f| File.file?(f) }.each do |file|
     file_hash = Digest::SHA1.hexdigest(File.basename(file))
     cache[file_hash] = file
   end

    cache
  end
end