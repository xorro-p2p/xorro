require_relative 'test_helper.rb'
require_relative "../node.rb"
require_relative "../routing_table.rb"
require_relative "../network_adapter.rb"

class NodeTest < Minitest::Test
  def setup
    @kn = NetworkAdapter.new
  end

  def test_create_node
    node = Node.new('0', @kn)

    assert_instance_of(Node, node)
    assert_instance_of(RoutingTable, node.routing_table)
  end

  def test_join_network
    node1 = Node.new('1', @kn)
    node2 = Node.new('2', @kn)

    assert_includes(@kn.nodes, node1)
    assert_includes(@kn.nodes, node2)
  end

  def test_ping_other_node_true_and_false
    node0 = Node.new('0', @kn)
    node1 = Node.new('1', @kn)
    node2 = Node.new('2', @kn)

    assert(node0.ping(node1.to_contact))
    assert(node0.ping(node2.to_contact))
    refute(node0.ping(Contact.new(id: '3', ip: '')))
  end

  def test_ping_dead_node
    
  end

  def test_receive_ping
    node0 = Node.new('0', @kn)
    node1 = Node.new('1', @kn)

    refute_includes(node0.routing_table.buckets[0].contacts, node1.to_contact)
    refute_includes(node1.routing_table.buckets[0].contacts, node0.to_contact)

    node0.ping(node1.to_contact)

    assert_equal(1, node1.routing_table.buckets[0].contacts.size)
    assert_equal(1, node0.routing_table.buckets[0].contacts.size)
  end

  def test_store
    node0 = Node.new('0', @kn)
    node1 = Node.new('1', @kn)

    node0.store('key', 'value', node1.to_contact)
    assert_equal('value', node1.dht_segment['key'])
  end

  def test_receive_find_node
    node0 = Node.new('0', @kn)
    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node12 = Node.new('12', @kn)
    node7 = Node.new('7', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)

    results = node0.receive_find_node('1', node7.to_contact)

    refute_empty(results)
    assert_equal(2, results.size)
    assert_includes(results, node4_contact)
    assert_includes(results, node5_contact)
  end

  def test_receive_find_node_multiple_buckets
    # checking to see if results will be taken from multiple buckets
    node0 = Node.new('0', @kn)
    node15 = Node.new('15', @kn)
    node14 = Node.new('14', @kn)
    node3 = Node.new('3', @kn)
    node7 = Node.new('7', @kn)

    node15_contact = node15.to_contact
    node14_contact = node14.to_contact
    node3_contact = node3.to_contact

    node0.routing_table.insert(node15_contact)
    node0.routing_table.insert(node14_contact)
    node0.routing_table.insert(node3_contact)

    results = node0.receive_find_node('1', node7.to_contact)

    refute_empty(results)
    assert_equal(2, results.size)
    assert_includes(results, node15_contact)
    assert_includes(results, node3_contact)
  end

  # def test_receive_find_node_multiple_buckets_starting_from_back
  #   # checking to see if results will be taken from multiple buckets
  #   node0 = Node.new('0', @kn)
  #   node4 = Node.new('4', @kn)
  #   node5 = Node.new('5', @kn)
  #   node12 = Node.new('12', @kn)
  #   node7 = Node.new('7', @kn)

  #   node4_contact = node4.to_contact
  #   node5_contact = node5.to_contact
  #   node12_contact = node12.to_contact

  #   node0.routing_table.insert(node4_contact)
  #   node0.routing_table.insert(node5_contact)
  #   node0.routing_table.insert(node12_contact)

  #   results = node0.receive_find_node('13', node7.to_contact)

  #   refute_empty(results)
  #   assert_equal(2, results.size)
  #   assert_includes(results, node12_contact)
  #   assert_includes(results, node4_contact)
  # end

  def test_receive_find_node_fewer_than_k_results
    node0 = Node.new('0', @kn)
    node15 = Node.new('15', @kn)
    node7 = Node.new('7', @kn)

    node0.routing_table.insert(node15.to_contact)

    results = node0.receive_find_node('1', node7.to_contact)

    refute_empty(results)
    assert_equal(1, results.size)
    assert_equal('15', results.first.id)
  end

  def test_receive_find_node_exclude_requestor
    node0 = Node.new('0', @kn)
    node15 = Node.new('15', @kn)
    node14 = Node.new('14', @kn)
    node3 = Node.new('3', @kn)
    node7 = Node.new('7', @kn)

    node15_contact = node15.to_contact
    node14_contact = node14.to_contact
    node3_contact = node3.to_contact
    node7_contact = node7.to_contact

    node0.routing_table.insert(node15_contact)
    node0.routing_table.insert(node14_contact)
    node0.routing_table.insert(node3_contact)
    node0.routing_table.insert(node7_contact)

    results = node0.receive_find_node('1', node7_contact)

    refute_includes(results, node7_contact)
    assert_equal(2, results.size)
    assert_includes(results, node15_contact)
    assert_includes(results, node3_contact)
  end

  def test_find_node
    node7 = Node.new('7', @kn) # the requestor node
    node0 = Node.new('0', @kn) # the node that gets the request
    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node12 = Node.new('12', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)

    results = node7.find_node('1', node0.to_contact)

    refute_empty(results)
    assert_equal(2, results.size)
    assert_includes(results, node4_contact)
    assert_includes(results, node5_contact)
  end

  def test_receive_find_value_with_match
    # return a address
    node0 = Node.new('0', @kn) # node that received request
    node0.dht_segment['10'] = 'some_address'

    node7 = Node.new('7', @kn) # node making the request

    result = node0.receive_find_value('10', node7.to_contact)

    assert_equal('some_address', result['data'])
  end

  def test_receive_find_value_with_no_match
    # just returns closest nodes

    node0 = Node.new('0', @kn) # node that received request
    node0.dht_segment['11'] = 'some_address'

    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node12 = Node.new('12', @kn)
    node13 = Node.new('13', @kn)
    node7 = Node.new('7', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact
    node13_contact = node13.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)
    node0.routing_table.insert(node13_contact)

    results = node0.receive_find_value('10', node7.to_contact)

    refute_empty(results['contacts'])
    assert_equal(2, results['contacts'].size)
    assert_includes(results['contacts'], node12_contact)
    assert_includes(results['contacts'], node13_contact)
  end

  def test_find_value_with_match
    node0 = Node.new('0', @kn) # node that received request
    node0.dht_segment['10'] = 'some_address'

    node7 = Node.new('7', @kn) # node making the request

    result = node7.find_value('10', node0.to_contact)

    assert_equal('some_address', result['data'])
  end

  def test_find_value_with_no_match
    node0 = Node.new('0', @kn) # node that received request
    node0.dht_segment['11'] = 'some_address'

    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node12 = Node.new('12', @kn)
    node13 = Node.new('13', @kn)
    node7 = Node.new('7', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact
    node13_contact = node13.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)
    node0.routing_table.insert(node13_contact)

    results = node7.find_value('10', node0.to_contact)

    refute_empty(results['contacts'])
    assert_equal(2, results['contacts'].size)
    assert_includes(results['contacts'], node12_contact)
    assert_includes(results['contacts'], node13_contact)
  end
end
