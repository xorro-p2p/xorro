require_relative 'test_helper.rb'
require_relative "../lib/binary.rb"
require_relative "../lib/contact.rb"
require 'pry'

class BinaryTest6 < Minitest::Test
  def setup
    ENV['bit_length'] = '6'
    ENV['k'] = '2'
  end

  def test_xor_distance
    assert_equal(1, Binary.xor_distance('0', '1'))
    assert_equal(2, Binary.xor_distance('0', '2'))
    assert_equal(3, Binary.xor_distance('1', '2'))
    assert_equal(8, Binary.xor_distance('0', '8'))
    assert_equal(9, Binary.xor_distance('1', '8'))
    assert_equal(10, Binary.xor_distance('2', '8'))
  end

  def test_shared_prefix_bit_length
    assert_equal(5, Binary.shared_prefix_bit_length('0', '1'))
    assert_equal(6, Binary.shared_prefix_bit_length('1', '1'))
    assert_equal(4, Binary.shared_prefix_bit_length('1', '2'))
    assert_equal(5, Binary.shared_prefix_bit_length('2', '3'))
    assert_equal(3, Binary.shared_prefix_bit_length('3', '4'))
    assert_equal(5, Binary.shared_prefix_bit_length('4', '5'))
    assert_equal(4, Binary.shared_prefix_bit_length('7', '5'))
    assert_equal(2, Binary.shared_prefix_bit_length('7', '8'))
    assert_equal(0, Binary.shared_prefix_bit_length('63', '0'))
  end

  def test_sha
    assert_equal('aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d', Binary.sha('hello'))
    assert_equal('356a192b7913b04c54574d18c28d46e6395428ab', Binary.sha('1'))
    assert_equal( 40, Binary.sha(rand(333).to_s).size)
    assert_equal( Binary.sha('should be the same'), Binary.sha('should be the same'))
  end

  def test_select_closest_xor
    array = ['1', '2','3','4','5'].map {|i| Contact.new({id: i})}
    assert_equal(Binary.select_closest_xor('0', array).id, '1')
    assert_equal(Binary.select_closest_xor('5', array).id, '5')
    assert_equal(Binary.select_closest_xor('15', array).id, '5')
  end

  def test_sort_by_xor!
    array = ['1', '2','3','4','5']
    shuffled = array.shuffle.map {|i| Contact.new({id: i})}
    result = Binary.sort_by_xor!('0', shuffled).map(&:id)
    assert_equal(array, result)
  end
end