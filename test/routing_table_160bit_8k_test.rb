require_relative 'test_helper.rb'
require_relative '../lib/node.rb'
require_relative "../lib/routing_table.rb"
require_relative "../lib/kbucket.rb"
require_relative "../lib/contact.rb"
require_relative "../lib/fake_network_adapter.rb"

class RoutingTableTest160bit8k < Minitest::Test
  def setup
    @kn = FakeNetworkAdapter.new
    @node = Node.new('0', @kn)
    @routing_table = @node.routing_table
    ENV['bit_length'] = '160'
    ENV['k'] = '8'
  end

  def test_create_routing_table
    assert_equal(1, @routing_table.buckets.size)
  end

  def test_insert_node_with_duplicate_id
    new_node = Node.new('0', @kn)

    @routing_table.insert(new_node)
    assert_equal(0, @routing_table.buckets[0].size)
  end

  def test_insert_if_bucket_not_full
    node15 = Node.new('15', @kn)
    node16 = Node.new('16', @kn)

    @routing_table.insert(node15)
    @routing_table.insert(node16)

    assert_equal(1, @routing_table.buckets.size)
    assert_equal(2, @routing_table.buckets[0].contacts.size)
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
    @routing_table.create_bucket

    no_shared_id = (2**(ENV['bit_length'].to_i) - 1).to_s

    result = @routing_table.find_closest_bucket(no_shared_id)

    assert_equal(result, @routing_table.buckets[0])
  end

  def test_insert_find_closest_bucket_with_two_buckets_one_shared_bit
    @routing_table.create_bucket
    one_shared_id = (2**(ENV['bit_length'].to_i - 2)).to_s

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
    node56 = Node.new('56', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node56.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node7 = Node.new('7', @kn)
    @routing_table.insert(node7.to_contact)

    index_of_second_last_bucket = Binary.shared_prefix_bit_length('0', '56')

    assert_equal(index_of_second_last_bucket + 2, @routing_table.buckets.size)
    assert_equal(8, @routing_table.buckets[index_of_second_last_bucket].contacts.size)
    assert_equal(1, @routing_table.buckets.last.contacts.size)
  end

  def test_insert_if_bucket_full_and_splittable_smaller_distance_insert_first
    node56 = Node.new('56', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node56.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node80 = Node.new('80', @kn) # this id is further

    index1 = Binary.shared_prefix_bit_length('0', '56')
    index2 = Binary.shared_prefix_bit_length('0', '80')

    @routing_table.insert(node80.to_contact)

    assert_equal(8, @routing_table.buckets[index1].contacts.size)
    assert_equal(1, @routing_table.buckets[index2].contacts.size)
    assert_equal(index1 + 1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance
    node56 = Node.new('56', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node56.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    bucket_idx = Binary.shared_prefix_bit_length('0', '56')

    node55 = Node.new('55', @kn) # same xor distance
    @routing_table.insert(node55.to_contact)

    assert_equal(8, @routing_table.buckets[bucket_idx].contacts.size)
    assert_equal(bucket_idx + 1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance_bucket_redistributable
    node31 = Node.new('31', @kn) # smaller xor
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node31.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    bucket_idx = Binary.shared_prefix_bit_length('0', '56') # 154

    node40 = Node.new('40', @kn) # inserting node with same xor distance
    @routing_table.insert(node40.to_contact)

    assert_equal(8, @routing_table.buckets[bucket_idx].contacts.size)
    assert_equal(1, @routing_table.buckets.last.contacts.size)
    assert_equal(bucket_idx + 2, @routing_table.buckets.size) # 156
  end

  def test_redistribute_one_bucket_to_two
    no_shared_id = (2**(ENV['bit_length'].to_i - 1)).to_s
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
    node31 = Node.new('31', @kn) # smaller xor
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node31.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    bucket_idx = Binary.shared_prefix_bit_length('0', '56')

    node30 = Node.new('30', @kn)
    @routing_table.insert(node30.to_contact)

    assert_equal(7, @routing_table.buckets[bucket_idx].contacts.size)
    assert_equal(2, @routing_table.buckets.last.contacts.size)
    assert_equal(bucket_idx + 2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable
    node56 = Node.new('56', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node56.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node31 = Node.new('31', @kn)
    @routing_table.insert(node31.to_contact)

    last_bucket_idx = Binary.shared_prefix_bit_length('0', '31')

    node40 = Node.new('40', @kn)
    @routing_table.insert(node40.to_contact)

    assert_equal(8, @routing_table.buckets[last_bucket_idx - 1].contacts.size)
    assert_equal(1, @routing_table.buckets.last.contacts.size)
    assert_equal(last_bucket_idx + 1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_live
    node56 = Node.new('56', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node56.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node31 = Node.new('31', @kn)
    @routing_table.insert(node31.to_contact)

    bucket_idx = Binary.shared_prefix_bit_length('0', '56')

    node40 = Node.new('40', @kn)
    @routing_table.insert(node40.to_contact)

    assert_equal('56', @routing_table.buckets[bucket_idx].tail.id)
    assert_equal('57', @routing_table.buckets[bucket_idx].head.id)
    assert_equal(bucket_idx + 2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_not_live
    node56 = Node.new('56', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node56.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node31 = Node.new('31', @kn)
    @routing_table.insert(node31.to_contact)

    bucket_idx = Binary.shared_prefix_bit_length('0', '56')

    @kn.nodes.delete_at(1)

    node40 = Node.new('40', @kn)
    @routing_table.insert(node40.to_contact)

    assert_equal('40', @routing_table.buckets[bucket_idx].tail.id)
    assert_equal('57', @routing_table.buckets[bucket_idx].head.id)
    assert_equal(bucket_idx + 2, @routing_table.buckets.size)
  end
end
