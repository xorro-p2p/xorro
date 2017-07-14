require_relative 'test_helper.rb'
require_relative "../node.rb"
require_relative "../routing_table.rb"
require_relative "../kademlia_network.rb"

class NodeTest < Minitest::Test
  def setup
    @kn = KademliaNetwork.new
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

    assert(node0.ping('1'))
    assert(node0.ping('2'))
    refute(node0.ping('3'))
  end

  def test_ping_dead_node
    
  end

  def test_receive_ping
    node0 = Node.new('0', @kn)
    node1 = Node.new('1', @kn)

    refute_includes(node0.routing_table.buckets[0].contacts, node1.to_contact)
    refute_includes(node1.routing_table.buckets[0].contacts, node0.to_contact)

    node0.ping('1')

    assert_equal(1, node1.routing_table.buckets[0].contacts.size)
    assert_equal(1, node0.routing_table.buckets[0].contacts.size)
  end
end