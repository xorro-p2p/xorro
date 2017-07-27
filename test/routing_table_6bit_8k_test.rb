require_relative 'test_helper.rb'
require_relative '../lib/node.rb'
require_relative "../lib/routing_table.rb"
require_relative "../lib/kbucket.rb"
require_relative "../lib/contact.rb"
require_relative "../lib/fake_network_adapter.rb"

class RoutingTableTest6bit8k < Minitest::Test
  def setup
    @kn = FakeNetworkAdapter.new
    @node = Node.new('0', @kn)
    @routing_table = @node.routing_table
    ENV['bit_length'] = '6'
    ENV['k'] = '8'
    # [32-63] [16-31] [8-15] [4-7] [2-3] [1]
  end

  def test_create_routing_table
    assert_equal(1, @routing_table.buckets.size)
  end

  def test_insert_node_with_duplicate_id
    new_node = Node.new('0',@kn)

    @routing_table.insert(new_node)
    assert_equal(0, @routing_table.buckets[0].size)
  end

  def test_insert_if_bucket_not_full
    node15 = Node.new('15', @kn)

    @routing_table.insert(node15)

    assert_equal(1, @routing_table.buckets.size)
    assert_equal(1, @routing_table.buckets[0].contacts.size)
  end

  def test_insert_find_closest_bucket_with_one_bucket
    result = @routing_table.find_closest_bucket('1')
    assert_equal(result, @routing_table.buckets[0])
  end

  def test_insert_find_closest_bucket_with_two_buckets_no_shared_bits
    @routing_table.create_bucket
    result = @routing_table.find_closest_bucket('60')

    assert_equal(result, @routing_table.buckets[0])
  end

  def test_insert_find_closest_bucket_with_two_buckets_one_shared_bit
    @routing_table.create_bucket
    result = @routing_table.find_closest_bucket('31')

    assert_equal(result, @routing_table.buckets[1])
  end

  def test_insert_find_closest_bucket_with_two_buckets_no_exact_shared_bits
    @routing_table.create_bucket
    result = @routing_table.find_closest_bucket('1')

    assert_equal(result, @routing_table.buckets[1])
  end

  def test_insert_find_closest_bucket_with_k_buckets_no_exact_shared_bits
    5.times do 
      @routing_table.create_bucket
    end

    result1 = @routing_table.find_closest_bucket('1')
    result7 = @routing_table.find_closest_bucket('7')
    result63 = @routing_table.find_closest_bucket('63')

    assert_equal(result1, @routing_table.buckets.last)
    assert_equal(result7, @routing_table.buckets[3])
    assert_equal(result63, @routing_table.buckets.first)
  end

  def test_insert_if_bucket_full_and_splittable_diff_xor_distance
    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    node7 = Node.new('7', @kn)

    @routing_table.insert(node32.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    @routing_table.insert(node7.to_contact)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_smaller_distance_insert_first
    node16 = Node.new('16', @kn)
    node17 = Node.new('17', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    node40 = Node.new('40', @kn)

    @routing_table.insert(node16.to_contact)
    @routing_table.insert(node17.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    @routing_table.insert(node40.to_contact)

    assert_equal(2, @routing_table.buckets.size)
    assert_equal(2, @routing_table.buckets.last.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance
    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    node40 = Node.new('40', @kn)

    @routing_table.insert(node32.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    @routing_table.insert(node40.to_contact)

    assert_equal(1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance_bucket_redistributable
    node7 = Node.new('7', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    node40 = Node.new('40', @kn)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    @routing_table.insert(node40.to_contact)
    
    assert_equal(2, @routing_table.buckets.size)
  end

  def test_redistribute_one_bucket_to_two
    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)

    node16 = Node.new('16', @kn)

    @routing_table.insert(node32.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)

    @routing_table.insert(node16.to_contact)

    @routing_table.create_bucket

    @routing_table.redistribute_contacts

    assert_equal(7, @routing_table.buckets[0].contacts.size)
    assert_equal(1, @routing_table.buckets[1].contacts.size)
  end

  def test_insert_if_bucket_full_and_splittable_but_contains_at_least_1_closer_element
    node3 = Node.new('3', @kn)
    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)

    node63 = Node.new('63', @kn)

    @routing_table.insert(node3.to_contact)
    @routing_table.insert(node32.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)

    @routing_table.insert(node63.to_contact)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable
    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node32.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node7 = Node.new('7', @kn)
    node6 = Node.new('6', @kn)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node6.to_contact)

    node40 = Node.new('40', @kn)
    @routing_table.insert(node40.to_contact)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_live
    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node32.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node7 = Node.new('7', @kn)
    node6 = Node.new('6', @kn)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node6.to_contact)

    node40 = Node.new('40', @kn)
    @routing_table.insert(node40.to_contact)

    assert_equal('32', @routing_table.buckets[0].tail.id)
    assert_equal('57', @routing_table.buckets[0].head.id)
    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_not_live
    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    @routing_table.insert(node32.to_contact)
    @routing_table.insert(node57.to_contact)
    @routing_table.insert(node58.to_contact)
    @routing_table.insert(node59.to_contact)
    @routing_table.insert(node60.to_contact)
    @routing_table.insert(node61.to_contact)
    @routing_table.insert(node62.to_contact)
    @routing_table.insert(node63.to_contact)

    node7 = Node.new('7', @kn)
    node6 = Node.new('6', @kn)

    @routing_table.insert(node7.to_contact)
    @routing_table.insert(node6.to_contact)

    @kn.nodes.delete_at(1)

    node40 = Node.new('40', @kn)
    @routing_table.insert(node40.to_contact)

    assert_equal('40', @routing_table.buckets[0].tail.id)
    assert_equal('57', @routing_table.buckets[0].head.id)
    assert_equal(2, @routing_table.buckets.size)
  end
end
