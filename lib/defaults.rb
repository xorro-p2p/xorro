require 'yaml'

module Defaults
  def self.setup(port)
    node_homes = File.expand_path("~/Desktop/node_homes")
    safe_mkdir(node_homes)
    create_node_home(node_homes, port)
  end

  def self.create_node_home(node_homes, port)
    node_home = File.join(node_homes, port.to_s)
    safe_mkdir(node_home)
    create_subfolders(node_home)
    ENV['home'] = node_home
  end

  def self.create_subfolders(node_home)
    uploads = File.join(node_home, "/uploads")
    manifests = File.join(node_home, "/manifests")
    shards = File.join(node_home, "/shards")

    [uploads, manifests, shards].each do |f|
      safe_mkdir(f)
      ENV[File.basename(f)] = f
      ### ENV['shards'] + ENV['manifests'] + ENV['uploads']
    end
  end

  def self.create_node(network, port)
    if Storage.file_exists? && Storage.valid_node?
      node = Storage.load_file
      node.generate_file_cache
      node.port = port
    else
      node = Node.new(new_id, network, port)
    end
    node.set_super
    node.sync
    node
  end

  def self.new_id
    rand(2 ** ENV['bit_length'].to_i).to_s
  end

  def self.safe_mkdir(dir)
    Dir.mkdir(dir) unless Dir.exists?(dir)
  end
end