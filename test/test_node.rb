require 'minitest/autorun'
require_relative "../node.rb"

class NodeTest < Minitest::Test
  def test_id_distance
    @node0 = Node.new('0')
    @node1 = Node.new('1')
    @node2 = Node.new('2')
    @node8 = Node.new('8')

    assert_equal(@node0.id_distance(@node1), 1)
    assert_equal(@node0.id_distance(@node2), 2)
    assert_equal(@node1.id_distance(@node2), 3)
    assert_equal(@node0.id_distance(@node8), 8)
    assert_equal(@node1.id_distance(@node8), 9)
    assert_equal(@node2.id_distance(@node8), 10)
  end
end