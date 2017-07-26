require_relative 'test_helper.rb'
require_relative "../lib/node.rb"
require_relative "../lib/routing_table.rb"
require_relative "../lib/fake_network_adapter.rb"
require_relative "../lib/kbucket.rb"

class NodeTest160bit8k < Minitest::Test
  def setup
    @kn = FakeNetworkAdapter.new
    ENV['bit_length'] = '160'
    ENV['k'] = '8'
    ENV['alpha'] = '3'
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

    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)

    node0.routing_table.insert(node32.to_contact)
    node0.routing_table.insert(node57.to_contact)
    node0.routing_table.insert(node58.to_contact)
    node0.routing_table.insert(node59.to_contact)
    node0.routing_table.insert(node60.to_contact)
    node0.routing_table.insert(node61.to_contact)
    node0.routing_table.insert(node62.to_contact)
    node0.routing_table.insert(node63.to_contact)

    node12 = Node.new('12', @kn)

    results = node0.receive_find_node('1', node12.to_contact)
    results.map! { |contact| contact.id }

    refute_empty(results)
    assert_equal(8, results.size)
    assert_includes(results, '32')
    assert_includes(results, '63')
  end

  def test_receive_find_node_multiple_buckets
    node0 = Node.new('0', @kn)

    node32 = Node.new('32', @kn)
    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)
    node7 = Node.new('7', @kn)

    node0.routing_table.insert(node32.to_contact)
    node0.routing_table.insert(node57.to_contact)
    node0.routing_table.insert(node58.to_contact)
    node0.routing_table.insert(node59.to_contact)
    node0.routing_table.insert(node60.to_contact)
    node0.routing_table.insert(node61.to_contact)
    node0.routing_table.insert(node62.to_contact)
    node0.routing_table.insert(node63.to_contact)
    node0.routing_table.insert(node7.to_contact)

    node12 = Node.new('12', @kn)

    results = node0.receive_find_node('1', node12.to_contact)
    results.map! { |contact| contact.id }

    refute_empty(results)
    assert_equal(8, results.size)
    assert_includes(results, '7')
    assert_includes(results, '32')
    assert_includes(results, '62')
  end

  def test_receive_find_node_multiple_buckets_starting_from_back
    node0 = Node.new('0', @kn)

    node57 = Node.new('57', @kn)
    node58 = Node.new('58', @kn)
    node59 = Node.new('59', @kn)
    node60 = Node.new('60', @kn)
    node61 = Node.new('61', @kn)
    node62 = Node.new('62', @kn)
    node63 = Node.new('63', @kn)
    node7 = Node.new('7', @kn)
    node8 = Node.new('8', @kn)

    node0.routing_table.insert(node57.to_contact)
    node0.routing_table.insert(node58.to_contact)
    node0.routing_table.insert(node59.to_contact)
    node0.routing_table.insert(node60.to_contact)
    node0.routing_table.insert(node61.to_contact)
    node0.routing_table.insert(node62.to_contact)
    node0.routing_table.insert(node63.to_contact)
    node0.routing_table.insert(node7.to_contact)
    node0.routing_table.insert(node8.to_contact)

    node12 = Node.new('12', @kn)

    results = node0.receive_find_node('40', node12.to_contact)
    results.map! { |contact| contact.id }

    refute_empty(results)
    assert_equal(8, results.size)
    assert_includes(results, '57')
    assert_includes(results, '63')
    assert_includes(results, '7')
    refute_includes(results, '8')
  end

  def test_receive_find_node_fewer_than_k_results
    node0 = Node.new('0', @kn)
    node15 = Node.new('15', @kn)
    node16 = Node.new('16', @kn)
    node7 = Node.new('7', @kn)

    node0.routing_table.insert(node15.to_contact)
    node0.routing_table.insert(node16.to_contact)

    results = node0.receive_find_node('1', node7.to_contact)

    refute_empty(results)
    assert_equal(2, results.size)
    assert_equal('15', results.first.id)
    assert_equal('16', results.last.id)
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
    assert_equal(3, results.size)
    assert_includes(results, node15_contact)
    assert_includes(results, node14_contact)
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
    assert_equal(3, results.size)
    assert_includes(results, node4_contact)
    assert_includes(results, node5_contact)
    assert_includes(results, node12_contact)
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
    assert_equal(4, results['contacts'].size)
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
    node7 = Node.new('7', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)

    results = node7.find_value('10', node0.to_contact)

    refute_empty(results['contacts'])
    assert_equal(3, results['contacts'].size)
    assert_includes(results['contacts'], node12_contact)
    assert_includes(results['contacts'], node5_contact)
    assert_includes(results['contacts'], node4_contact)
  end

  def test_iterative_find_node
    # no parallelism
    node0 = Node.new('0', @kn)
    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node9 = Node.new('9', @kn)
    node10 = Node.new('10', @kn)
    node11 = Node.new('11', @kn)
    node12 = Node.new('12', @kn)
    node14 = Node.new('14', @kn)
    node13 = Node.new('13', @kn)

    node0.routing_table.insert(node4.to_contact)
    node0.routing_table.insert(node5.to_contact)
    node0.routing_table.insert(node9.to_contact)
    node0.routing_table.insert(node10.to_contact)

    node4.routing_table.insert(node11.to_contact)
    node4.routing_table.insert(node12.to_contact)
    node4.routing_table.insert(node13.to_contact)

    node14_contact = node14.to_contact

    node11.routing_table.insert(node14_contact)

    result = node0.iterative_find_node('15').map(&:id)

    assert_instance_of(Array, result)
    assert_equal(7, result.size)
    assert_includes(result, '14')
    assert_includes(result, '12')
    refute_includes(result, '10')
    # test that ping adds new contact to our routing table
    assert_includes(node0.routing_table.buckets[0].map(&:id), node14_contact.id)
  end

  def test_iterative_store
    node0 = Node.new('0', @kn)
    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node12 = Node.new('12', @kn)
    node14 = Node.new('14', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact
    node14_contact = node14.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)

    node12.routing_table.insert(node14_contact)
    node0.iterative_store('13', 'some_address')

    assert_equal('some_address', node12.dht_segment['13'])
    assert_equal('some_address', node4.dht_segment['13'])
    assert_equal('some_address', node5.dht_segment['13'])
    refute(node14.dht_segment['13'])   
  end

  def test_iterative_find_value_with_match
    node0 = Node.new('0', @kn)
    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node12 = Node.new('12', @kn)
    node14 = Node.new('14', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact
    node14_contact = node14.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)

    node12.routing_table.insert(node14_contact)
    node0.store('15', 'some_address', node14_contact)

    result = node0.iterative_find_value('15')
    assert_instance_of(String, result)
    assert_equal('some_address', result)
    # store in second closest node
    assert_equal('some_address', node4.dht_segment['15'])
  end

  def test_iterative_find_value_with_no_match
    node0 = Node.new('0', @kn)
    node4 = Node.new('4', @kn)
    node5 = Node.new('5', @kn)
    node12 = Node.new('12', @kn)
    node14 = Node.new('14', @kn)

    node4_contact = node4.to_contact
    node5_contact = node5.to_contact
    node12_contact = node12.to_contact
    node14_contact = node14.to_contact

    node0.routing_table.insert(node4_contact)
    node0.routing_table.insert(node5_contact)
    node0.routing_table.insert(node12_contact)

    node12.routing_table.insert(node14_contact)
    node0.store('13', 'some_address', node14_contact)

    result = node0.iterative_find_value('15')
    assert_instance_of(Array, result)
    assert_equal(4, result.size)
    assert_includes(result.map(&:id), node4_contact.id)
    assert_includes(result.map(&:id), node5_contact.id)
    assert_includes(result.map(&:id), node14_contact.id)
    assert_includes(result.map(&:id), node12_contact.id)
  end
end
