require_relative 'test_helper.rb'
require_relative '../network_adapter.rb'

class NetworkAdapterTest < Minitest::Test
  def setup
    @kn = NetworkAdapter.new
  end

  def test_create_network_adapter
    assert_instance_of(NetworkAdapter, @kn)
  end

  def test_kn_has_nodes
    assert_equal([], @kn.nodes)
  end

end