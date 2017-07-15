require_relative 'development.rb'
require_relative 'binary.rb'
require 'pry'

class RoutingTable
  attr_accessor :node, :node_id, :buckets

  def initialize(current_node)
    @node = current_node
    @node_id = current_node.id
    @buckets = [KBucket.new(@node)]
  end

  # insert a new node into one of the k-buckets
  def insert(contact)
    raise ArgumentError, 'cannot add self' if contact.id == @node_id

    shared_bit_length = Binary.shared_prefix_bit_length(@node_id, contact.id)

    bucket = find_matching_bucket(shared_bit_length)
    duplicate_contact = bucket.find_contact_by_id(contact.id)

    if duplicate_contact
      duplicate_contact.update_last_seen
      return
    end

    node_is_closer = shared_bit_length > @buckets.index(bucket)  ###Bool

    if bucket.is_full?
      if bucket.is_splittable? && room_for_another_bucket? &&
         (node_is_closer ||
          bucket.is_redistributable?(@node_id, @buckets.index(bucket)))
        split(bucket)
        insert(contact)
      else
        bucket.attempt_eviction(contact)
      end
    else
      bucket.add(contact)
    end
  end

  # find the bucket that has the matching/closest XOR distance
  def find_matching_bucket(idx)
    buckets[idx] || buckets.last
  end

  def room_for_another_bucket?
    buckets.size < ENV['bit_length'].to_i
  end

  def create_bucket
    buckets.push KBucket.new(@node)
  end

  def split(bucket)
    bucket.make_unsplittable
    create_bucket
    redistribute_contacts
  end

  # redistribute contacts between buckets.last and a newly created bucket
  def redistribute_contacts
    old_idx = buckets.size - 2
    old_bucket = buckets[old_idx]
    new_bucket = buckets.last

    movers = old_bucket.contacts.select do |c|
      Binary.shared_prefix_bit_length(@node_id, c.id) > old_idx
    end

    movers.each do |m|
      old_bucket.delete(m)
      new_bucket.contacts.push(m)    ####TODO REFACTOR THIS IT IS NOT GOOD
    end
  end
end