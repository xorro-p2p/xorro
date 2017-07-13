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

    shared_bit_length = @node.shared_prefix_bit_length(node)

    bucket = find_matching_bucket(shared_bit_length)
    node_is_closer = shared_bit_length > @buckets.index(bucket)  ###Bool

    node_info = {:id => node.id, :ip => node.ip}

    if bucket.is_full?
      if bucket.is_splittable? && (node_is_closer || bucket.is_redistributable?) ### AND (|| (at least one member of bucket has greater shared bitlength than index of bucket)
        create_bucket
        redistribute_contacts
        @buckets.last.add(node_info)
      else
        bucket.attempt_eviction(node_info)
      end
    else
      bucket.add(node_info)
    end
  end

  # find the bucket that has the matching/closest XOR distance
  def find_matching_bucket(shared_bit_length)
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
    old_idx = @buckets.size - 2
    old_bucket = @buckets[old_idx]
    new_bucket = @buckets.last

    movers = old_bucket.contacts.select do |c|
      shared_bit_length = @node.shared_prefix_bit_length(c)
      node_is_closer = shared_bit_length > old_idx
      return node_is_closer
    end

    binding.pry

    movers.each do |m|
      old_bucket.delete(m)
      new_bucket.contacts.push(m)    ####TODO REFACTOR THIS IT IS NOT GOOD
    end

  end

  # delete a node from a bucket - should this only refer to a method in KBucket class?
  def delete(node)

  end
end