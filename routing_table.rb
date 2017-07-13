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
    duplicate_contact = bucket.find_contact_by_id(node.id)

    if duplicate_contact
      duplicate_contact.update_last_seen
      return
    end

    node_is_closer = shared_bit_length > @buckets.index(bucket)  ###Bool

    node_info = {:id => node.id, :ip => node.ip}

    if bucket.is_full?
      if bucket.is_splittable? &&
         @buckets.size < ENV['bit_length'].to_i &&
         (node_is_closer ||
          bucket.is_redistributable?(@node, @buckets.index(bucket)))
        bucket.make_unsplittable
        create_bucket
        redistribute_contacts
        insert(node)
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

  def create_bucket
    @buckets.push KBucket.new
  end

  # redistribute contacts between buckets.last and a newly created bucket
  def redistribute_contacts
    old_idx = @buckets.size - 2
    old_bucket = @buckets[old_idx]
    new_bucket = @buckets.last

    movers = old_bucket.contacts.select do |c|
      shared_bit_length = @node.shared_prefix_bit_length(c)
      node_is_closer = shared_bit_length > old_idx

      node_is_closer
    end

    movers.each do |m|
      old_bucket.delete(m)
      new_bucket.contacts.push(m)    ####TODO REFACTOR THIS IT IS NOT GOOD
    end

  end
end