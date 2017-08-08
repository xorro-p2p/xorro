require 'yaml'

module Defaults
  ENVIRONMENT = {
    k: 8,
    bit_length: 160,
    alpha: 3
  }

  def self.setup(port)
    node_homes = File.expand_path(ENV['node_homes'])
    safe_mkdir(node_homes)
    create_node_home(node_homes, port)
  end

  def self.create_node_home(node_homes, port)
    node_home = File.join(node_homes, port.to_s)
    safe_mkdir(node_home)
    create_subfolders(node_home)
    ENVIRONMENT[:xorro_home] = node_home
  end

  def self.create_subfolders(node_home)
    files = File.join(node_home, "/files")
    manifests = File.join(node_home, "/manifests")
    shards = File.join(node_home, "/shards")

    [files, manifests, shards].each do |f|
      safe_mkdir(f)
      ENVIRONMENT[File.basename(f).to_sym] = f
      ### :shards, :files, :manifests
    end
  end

  def self.create_node(network, port)
    if Storage.file_exists? && Storage.valid_node?
      node = Storage.load_file
      node.generate_file_cache
    else
      node = Node.new(new_id, network, port)
    end
    node.set_super
    node.sync
    node
  end

  def self.new_id
    rand(2**ENVIRONMENT[:bit_length]).to_s
  end

  def self.safe_mkdir(dir)
    Dir.mkdir(dir) unless Dir.exist?(dir)
  end
end
