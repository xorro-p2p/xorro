require 'digest/sha1'

module Binary
  def self.xor_distance(id_string1, id_string2)
    id_string1.to_i ^ id_string2.to_i
  end

  def self.shared_prefix_bit_length(id_string1, id_string2)
    xor_distance = Binary.xor_distance(id_string1, id_string2)
    ENV['bit_length'].to_i - (Math.log2(xor_distance).floor + 1)
  end

  def self.sha(str)
    Digest::SHA1.hexdigest(str)
  end
end