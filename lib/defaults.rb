require 'yaml'

module Defaults
  def self.setup(port)
    node_homes = File.expand_path("~/Desktop/node_homes")
    Dir.mkdir(node_homes) unless Dir.exists?(node_homes)
    create_node_home(node_homes, port)
  end

  def self.create_node_home(node_homes, port)
    node_home = File.join(node_homes, port.to_s)
    Dir.mkdir(node_home) unless Dir.exists?(node_home)
    create_uploads_folder(node_home)
    ENV['home'] = node_home
  end

  def self.create_uploads_folder(node_home)
    uploads = File.join(node_home, "/uploads")
    Dir.mkdir(uploads) unless Dir.exists?(uploads)
    ENV['uploads'] = uploads
  end

  def self.create_node(network, port)
    if Storage.file_exists? && Storage.valid_node?
      node = Storage.load_file
      node.generate_file_cache
      node.port = port
    else
      node = Node.new(new_id, network, port)
    end
    node.promote if ENV['SUPER'] == 'true'
    node.demote unless ENV['SUPER'] == 'false'
    node.sync
    node
  end

  def self.new_id
    rand(2 ** ENV['bit_length'].to_i).to_s
  end
end