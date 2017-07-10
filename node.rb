require 'open-uri'
require 'digest/sha1'


class Node
  attr_accessor :ip, :id, :files
  def initialize
    @ip = lookup_ip
    @id = sha(@ip)
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

  private

  def sha(str)
    Digest::SHA1.hexdigest(str)
  end
end