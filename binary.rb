require 'digest/sha1'

module Binary
  def self.xor_distance(id_string1, id_string2)
    id_string1.to_i ^ id_string2.to_i
  end

  def self.shared_prefix_bit_length(id_string1, id_string2)
    distance = xor_distance(id_string1, id_string2)
    ENV['bit_length'].to_i - (Math.log2(distance).floor + 1)
  end

  def self.sha(str)
    Digest::SHA1.hexdigest(str)
  end

  def self.xor_distance_map(source_node_id, array)
    array.map do |item|
      shared_prefix_bit_length(source_node_id, item.id)
    end
  end

  def self.select_closest_xor(id, array)
    xors = array.map {|el| el.id.to_i ^ id.to_i }
    array[xors.index(xors.min)]
  end
end