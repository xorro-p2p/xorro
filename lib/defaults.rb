require 'yaml'

module Defaults
  def self.setup(port)
    node_homes = File.expand_path(ENV['node_homes'])
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
    create_id_file(node_home)
  end

  def self.create_id_file(node_home)
    id_file = File.join(node_home, "/id.yml")

    unless File.exists?(id_file) && is_valid_id_file(id_file)
      id = new_id
      File.write(id_file, {id: id}.to_yaml)
    end
  end

  def self.is_valid_id_file(id_file)
    f = YAML::load_file(id_file)
    f && f[:id] && f[:id].to_i.between?(0,2 ** ENV['bit_length'].to_i)
  end

  def self.new_id
    rand(2 ** ENV['bit_length'].to_i).to_s
  end
end