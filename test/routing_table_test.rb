require_relative 'test_helper.rb'
require_relative '../node.rb'
require_relative "../routing_table.rb"
require_relative "../kbucket.rb"
require_relative "../contact.rb"

class RoutingTableTest < Minitest::Test
  def setup
    @node = Node.new('0')
    @routing_table = RoutingTable.new(@node)
  end

  def test_create_routing_table
    assert_equal(@node, @routing_table.node)
    assert_equal(1, @routing_table.buckets.size)
  end

  def test_insert_node_with_duplicate_id
    new_node = Node.new('0')

    assert_raises(ArgumentError) do
      @routing_table.insert(new_node)
    end
  end

  def test_insert_if_bucket_not_full
    node15 = Node.new('15')

    @routing_table.insert(node15)

    assert_equal(1, @routing_table.buckets.size)
    assert_equal(1, @routing_table.buckets[0].contacts.size)
  end

  def test_insert_find_matching_bucket_with_one_bucket
    new_node = Node.new('1')
    shared_bit_length = @node.shared_prefix_bit_length(new_node)
    result = @routing_table.find_matching_bucket(shared_bit_length)
    assert_equal(result, @routing_table.buckets[0])
  end

  def test_insert_find_matching_bucket_with_two_buckets_no_shared_bits
    new_node = Node.new('15')
    @routing_table.create_bucket
    shared_bit_length = @node.shared_prefix_bit_length(new_node)
    result = @routing_table.find_matching_bucket(shared_bit_length)

    assert_equal(result, @routing_table.buckets[0])
  end

  def test_insert_find_matching_bucket_with_two_buckets_one_shared_bit
    new_node = Node.new('7')
    @routing_table.create_bucket
    shared_bit_length = @node.shared_prefix_bit_length(new_node)
    result = @routing_table.find_matching_bucket(shared_bit_length)

    assert_equal(result, @routing_table.buckets[1])
  end

  def test_insert_find_matching_bucket_with_two_buckets_no_exact_shared_bits
    new_node = Node.new('1')
    @routing_table.create_bucket
    shared_bit_length = @node.shared_prefix_bit_length(new_node)
    result = @routing_table.find_matching_bucket(shared_bit_length)

    assert_equal(result, @routing_table.buckets[1])
  end

  def test_insert_find_matching_bucket_with_k_buckets_no_exact_shared_bits
    node2 = Node.new('2')
    node7 = Node.new('7')
    node15 = Node.new('15')

    shared_bit_length2 = @node.shared_prefix_bit_length(node2)
    shared_bit_length7 = @node.shared_prefix_bit_length(node7)
    shared_bit_length15 = @node.shared_prefix_bit_length(node15)

    3.times do 
      @routing_table.create_bucket
    end

    result2 = @routing_table.find_matching_bucket(shared_bit_length2)
    result7 = @routing_table.find_matching_bucket(shared_bit_length7)
    result15 = @routing_table.find_matching_bucket(shared_bit_length15)

    assert_equal(result2, @routing_table.buckets[2])
    assert_equal(result7, @routing_table.buckets[1])
    assert_equal(result15, @routing_table.buckets[0])
  end

  def test_insert_if_bucket_full_and_splittable_diff_xor_distance
    # result is buckets.size = 2
    node14 = Node.new('14')
    node15 = Node.new('15')
    node7 = Node.new('7')

    @routing_table.insert(node14)
    @routing_table.insert(node15)
    @routing_table.insert(node7)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance
    node14 = Node.new('14')
    node15 = Node.new('15')
    node13 = Node.new('13')

    @routing_table.insert(node14)
    @routing_table.insert(node15)
    @routing_table.insert(node13)

    assert_equal(1, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_splittable_same_xor_distance_bucket_redistributable
    node7 = Node.new('7')
    node15 = Node.new('15')
    node13 = Node.new('13')

    @routing_table.insert(node7)
    @routing_table.insert(node15)
    @routing_table.insert(node13)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_redistribute_one_bucket_to_two
    node15 = Node.new('15')
    node3 = Node.new('3')
    node5 = Node.new('5')

    @routing_table.insert(node15)
    @routing_table.insert(node3)

    @routing_table.create_bucket

    @routing_table.redistribute_contacts

    assert_equal(1, @routing_table.buckets[0].contacts.size)
    assert_equal(1, @routing_table.buckets[1].contacts.size)
  end

  def test_insert_if_bucket_full_and_splittable_but_contains_at_least_1_closer_element
    node3 = Node.new('3')
    node15 = Node.new('15')
    node13 = Node.new('13')

    @routing_table.insert(node3)
    @routing_table.insert(node15)
    @routing_table.insert(node13)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable
    node15 = Node.new('15')
    node14 = Node.new('14')

    @routing_table.insert(node15)
    @routing_table.insert(node14)

    node7 = Node.new('7')
    node6 = Node.new('6')

    @routing_table.insert(node7)
    @routing_table.insert(node6)

    node13 = Node.new('13')
    @routing_table.insert(node13)

    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_live
    node15 = Node.new('15')
    node14 = Node.new('14')

    @routing_table.insert(node15)
    @routing_table.insert(node14)

    node7 = Node.new('7')
    node6 = Node.new('6')

    @routing_table.insert(node7)
    @routing_table.insert(node6)

    node13 = Node.new('13')
    @routing_table.insert(node13)

    assert_equal('15', @routing_table.buckets[0].tail.id)
    assert_equal('14', @routing_table.buckets[0].head.id)
    assert_equal(2, @routing_table.buckets.size)
  end

  def test_insert_if_bucket_full_and_not_splittable_and_head_node_not_live
    node15 = Node.new('15')
    node14 = Node.new('14')

    @routing_table.insert(node15)
    @routing_table.insert(node14)

    @routing_table.buckets[0].contacts[0].pingable = false

    node7 = Node.new('7')
    node6 = Node.new('6')

    @routing_table.insert(node7)
    @routing_table.insert(node6)

    node13 = Node.new('13')
    @routing_table.insert(node13)

    assert_equal('13', @routing_table.buckets[0].tail.id)
    assert_equal('14', @routing_table.buckets[0].head.id)
    assert_equal(2, @routing_table.buckets.size)
  end
end
