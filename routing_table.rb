require_relative 'development.rb'
require 'pry'

class RoutingTable
  attr_accessor :node, :buckets

  def initialize(node)
    # so we can easily reference our node
    @node = node
    @buckets = [KBucket.new]
  end

  # implement the each method for our custom KBucket object
  include Enumerable
  def each(&block)
    @buckets.each do |b|
      b.each(&block)
    end
  end

  # insert a new node into one of the k-buckets
  def insert(node)
    raise ArgumentError, 'cannot add self' if node.id == @node.id

    bucket = find_matching_bucket(node)
    # binding.pry
    node_info = {:id => node.id, :ip => node.ip}

    if bucket.is_full?
      if bucket.is_splittable?
        create_bucket
        @buckets.last.add(node_info)
      else
        bucket.attempt_eviction(node_info)
      end
    else
      bucket.add(node_info)
    end
  end

  # find the bucket that has the matching/closest XOR distance
  def find_matching_bucket(new_node)
    xor_distance = @node.id_distance(new_node)

    shared_bit_length = ENV['bit_length'].to_i - (Math.log2(xor_distance).floor + 1)
    buckets[shared_bit_length] || buckets.last
  end

  def splittable?(bucket)
    @buckets.last == bucket
  end

  # replace this with split bucket
  def create_bucket
    @buckets.push KBucket.new
  end

  # split the last bucket
  def split_bucket

  end

  # redistribute contacts between buckets.last and a newly created bucket
  def redistribute_contacts
    old_idx = @routing_table.buckets.size - 2
    old_bucket = @routing_table.buckets[old_idx]
    new_bucket = @routing_table.buckets.last

  end

  # delete a node from a bucket - should this only refer to a method in KBucket class?
  def delete(node)

  end
end