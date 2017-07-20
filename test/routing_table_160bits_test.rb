require_relative 'test_helper.rb'
require_relative '../lib/node.rb'
require_relative "../lib/routing_table.rb"
require_relative "../lib/kbucket.rb"
require_relative "../lib/contact.rb"
require_relative "../lib/network_adapter.rb"

class RoutingTableTest < Minitest::Test
  def setup
    @kn = NetworkAdapter.new
    @node = Node.new('0', @kn)
    @routing_table = @node.routing_table
    ENV['bit_length'] = '160'
    ENV['k'] = '2'
  end

  def test_create_routing_table
    assert_equal(1, @routing_table.buckets.size)
  end

  def test_insert_node_with_duplicate_id
    new_node = Node.new('0',@kn)

    assert_raises(ArgumentError) do
      @routing_table.insert(new_node)
    end
  end

  def test_insert_if_bucket_not_full
    node15 = Node.new('15', @kn)

    @routing_table.insert(node15)

    assert_equal(1, @routing_table.buckets.size)
    assert_equal(1, @routing_table.buckets[0].contacts.size)
  end

  def test_insert_find_closest_bucket_with_one_bucket_with_closest_shared_bit_length
    result = @routing_table.find_closest_bucket('1')
    assert_equal(result, @routing_table.buckets[0])
  end

  def test_insert_find_closest_bucket_with_two_buckets_no_shared_bit_length
    @routing_table.create_bucket

    no_shared_id = (2 ** (ENV['bit_length'].to_i - 1)).to_s

    result = @routing_table.find_closest_bucket(no_shared_id)

    assert_equal(result, @routing_table.buckets[0])    
  end

  def test_insert_find_closest_bucket_with_two_buckets_no_shared_bit_length_bug
    ENV['bit_length'] = '160'
    @routing_table.create_bucket

    no_shared_id = (2 ** (ENV['bit_length'].to_i) - 1).to_s

    result = @routing_table.find_closest_bucket(no_shared_id)
    
    assert_equal(result, @routing_table.buckets[0])    
  end

  def test_insert_find_closest_bucket_with_two_buckets_one_shared_bit
    @routing_table.create_bucket
    one_shared_id = (2 ** (ENV['bit_length'].to_i - 2)).to_s

    result = @routing_table.find_closest_bucket(one_shared_id)

    assert_equal(result, @routing_table.buckets[1])
  end

  def test_insert_find_closest_bucket_with_two_buckets_with_most_shared_bits
    @routing_table.create_bucket
    result = @routing_table.find_closest_bucket('1')

    assert_equal(result, @routing_table.buckets[1])
  end

  def test_insert_find_closest_bucket_with_full_buckets_with_arbitrary_shared_bits
    total_buckets = ENV['bit_length'].to_i - 1 # create bucket equal to k

    total_buckets.times do
      @routing_table.create_bucket
    end

    result2 = @routing_table.find_closest_bucket('2')
    position = Binary.shared_prefix_bit_length('0', '2')
    result7 = @routing_table.find_closest_bucket('7')
    position2 = Binary.shared_prefix_bit_length('0', '7')
    result15 = @routing_table.find_closest_bucket('15')
    position3 = Binary.shared_prefix_bit_length('0', '15')

    assert_equal(result2, @routing_table.buckets[position])

    assert_equal(result7, @routing_table.buckets[position2])

    assert_equal(result15, @routing_table.buckets[position3])
  end

  def test_insert_if_bucket_full_and_splittable_diff_xor_distance
    node_id = '7'

    node14 = Node.new('14', @kn)
    node15 = Node.new('15', @kn)
    node7 = Node.new(node_id, @kn)

    index_of_inserted_bucket = Binary.shared_prefix_bit_length('0', node_id)
    
    @routing_table.insert(node14.to_contact)
    @routing_table.insert(node15.to_contact)
    @routing_table.insert(node7.to_contact)
 
    assert_equal(index_of_inserted_bucket + 1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_smaller_distance_insert_first
    node7 = Node.new('7', @kn) # 7 and 6 are same distance
    node6 = Node.new('6', @kn) # 7 and 6 are same distance
    node13 = Node.new('13', @kn) # this id is further

    index1 = Binary.shared_prefix_bit_length('0', '7')
    index2 = Binary.shared_prefix_bit_length('0', '13')
    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node6.to_contact)
    @routing_table.insert(node13.to_contact)

    index_of_last_bucket = Binary.shared_prefix_bit_length('0', '7')

    assert_equal(2, @routing_table.buckets[index1].contacts.size)
    assert_equal(1, @routing_table.buckets[index2].contacts.size)
    assert_equal(index_of_last_bucket + 1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance
    node14 = Node.new('14', @kn)
    node15 = Node.new('15', @kn)
    node13 = Node.new('13', @kn)

    index_of_last_bucket = Binary.shared_prefix_bit_length('0', '14')

    @routing_table.insert(node14.to_contact)
    @routing_table.insert(node15.to_contact)
    @routing_table.insert(node13.to_contact)

    assert_equal(2, @routing_table.buckets[index_of_last_bucket].contacts.size)
    assert_equal(index_of_last_bucket + 1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance_bucket_redistributable
    node7 = Node.new('7', @kn)
    node15 = Node.new('15', @kn)
    node13 = Node.new('13', @kn)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node15.to_contact)
    @routing_table.insert(node13.to_contact)

    index_of_last_bucket = Binary.shared_prefix_bit_length('0', '7')


    assert_equal(1, @routing_table.buckets[index_of_last_bucket].contacts.size)
    assert_equal(2, @routing_table.buckets[index_of_last_bucket - 1].contacts.size)
    assert_equal(index_of_last_bucket + 1, @routing_table.buckets.size)
  end

  def test_redistribute_one_bucket_to_two
    no_shared_id = (2 ** (ENV['bit_length'].to_i - 1)).to_s
    node_no_shared = Node.new(no_shared_id, @kn)
    node3 = Node.new('3', @kn)

    @routing_table.insert(node_no_shared.to_contact)
    @routing_table.insert(node3.to_contact)

    @routing_table.create_bucket

    @routing_table.redistribute_contacts

    assert_equal(1, @routing_table.buckets[0].contacts.size)
    assert_equal(1, @routing_table.buckets[1].contacts.size)
  end

  def test_insert_if_bucket_full_and_splittable_but_contains_at_least_1_closer_element
    no_shared_id = (2 ** (ENV['bit_length'].to_i - 1)).to_s

    node3 = Node.new('3', @kn)
    node_no_shared = Node.new(no_shared_id, @kn)
    node13 = Node.new('13', @kn)

    @routing_table.insert(node3)
    @routing_table.insert(node_no_shared)
    @routing_table.insert(node13)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable
    no_shared_id = (2 ** (ENV['bit_length'].to_i - 1)).to_s
    no_shared_id2 = (2 ** (ENV['bit_length'].to_i - 1) + 1).to_s
    no_shared_id3 = (2 ** (ENV['bit_length'].to_i - 1) + 2).to_s

    node_no_shared_1 = Node.new(no_shared_id, @kn)
    node_no_shared_2 = Node.new(no_shared_id2, @kn)
    

    @routing_table.insert(node_no_shared_1.to_contact)
    @routing_table.insert(node_no_shared_2.to_contact)

    node7 = Node.new('7', @kn)
    node6 = Node.new('6', @kn)

    a = Binary.shared_prefix_bit_length('0', no_shared_id)
    b = Binary.shared_prefix_bit_length('0', no_shared_id2)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node6.to_contact)

    node_no_shared_3 = Node.new(no_shared_id3, @kn)
    @routing_table.insert(node_no_shared_3.to_contact)

    assert_equal(2, @routing_table.buckets[0].contacts.size)
    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_live
    no_shared_id = (2 ** (ENV['bit_length'].to_i - 1)).to_s
    no_shared_id2 = (2 ** (ENV['bit_length'].to_i - 1) + 1).to_s
    no_shared_id3 = (2 ** (ENV['bit_length'].to_i - 1) + 2).to_s

    node_no_shared_1 = Node.new(no_shared_id, @kn)
    node_no_shared_2 = Node.new(no_shared_id2, @kn)
    

    @routing_table.insert(node_no_shared_1.to_contact)
    @routing_table.insert(node_no_shared_2.to_contact)

    node7 = Node.new('7', @kn)
    node6 = Node.new('6', @kn)

    a = Binary.shared_prefix_bit_length('0', no_shared_id)
    b = Binary.shared_prefix_bit_length('0', no_shared_id2)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node6.to_contact)

    node_no_shared_3 = Node.new(no_shared_id3, @kn)
    @routing_table.insert(node_no_shared_3.to_contact)  

    assert_equal(no_shared_id, @routing_table.buckets[0].tail.id)
    assert_equal(no_shared_id2, @routing_table.buckets[0].head.id)
    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_not_live
    no_shared_id = (2 ** (ENV['bit_length'].to_i - 1)).to_s
    no_shared_id2 = (2 ** (ENV['bit_length'].to_i - 1) + 1).to_s
    no_shared_id3 = (2 ** (ENV['bit_length'].to_i - 1) + 2).to_s

    node_no_shared_1 = Node.new(no_shared_id, @kn)
    node_no_shared_2 = Node.new(no_shared_id2, @kn)
    

    @routing_table.insert(node_no_shared_1.to_contact)
    @routing_table.insert(node_no_shared_2.to_contact)

    node7 = Node.new('7', @kn)
    node6 = Node.new('6', @kn)

    a = Binary.shared_prefix_bit_length('0', no_shared_id)
    b = Binary.shared_prefix_bit_length('0', no_shared_id2)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node6.to_contact)

    @kn.nodes.delete_at(1)

    node_no_shared_3 = Node.new(no_shared_id3, @kn)
    @routing_table.insert(node_no_shared_3.to_contact)  

    assert_equal(no_shared_id3, @routing_table.buckets[0].tail.id)
    assert_equal(no_shared_id2, @routing_table.buckets[0].head.id)
    assert_equal(2, @routing_table.buckets.size)
  end
end
