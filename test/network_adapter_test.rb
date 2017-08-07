require_relative 'test_helper.rb'
require_relative '../lib/fake_network_adapter.rb'

class NetworkAdapterTest < Minitest::Test
  def setup
    @kn = FakeNetworkAdapter.new
  end

  def test_create_network_adapter
    assert_instance_of(FakeNetworkAdapter, @kn)
  end

  def test_kn_has_nodes
    assert_equal([], @kn.nodes)
  end
end
