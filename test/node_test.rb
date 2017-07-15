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

    node0.routing_table.insert(node4.to_contact)
    node0.routing_table.insert(node5.to_contact)
    node0.routing_table.insert(node12.to_contact)

    results = node0.receive_find_node('1', node7.to_contact)
        # binding.pry
    refute_empty(results)
    assert_equal(2, results.size)
  end
end
