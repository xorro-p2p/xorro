require 'minitest/autorun'
require_relative "../node.rb"

class NodeTest < Minitest::Test
  def test_id_distance
    @node0 = Node.new('0')
    @node1 = Node.new('1')
    @node2 = Node.new('2')
    @node8 = Node.new('8')

    assert_equal(1, @node0.id_distance(@node1))
    assert_equal(2, @node0.id_distance(@node2))
    assert_equal(3, @node1.id_distance(@node2))
    assert_equal(8, @node0.id_distance(@node8))
    assert_equal(9, @node1.id_distance(@node8))
    assert_equal(10, @node2.id_distance(@node8))
  end
end