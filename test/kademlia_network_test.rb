require_relative 'test_helper.rb'
require_relative '../kademlia_network.rb'

class KademliaNetworkTest < Minitest::Test
  def setup
    @kn = KademliaNetwork.new
  end

  def test_create_kademlia_network
    assert_instance_of(KademliaNetwork, @kn)
  end

  def test_kn_has_nodes
    assert_equal([], @kn.nodes)
  end

end