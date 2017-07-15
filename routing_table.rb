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

  include Enumerable
  def each(&block)
    @buckets.each do |b|
      yield b
    end
  end

  # insert a new node into one of the k-buckets
  def insert(contact)
    raise ArgumentError, 'cannot add self' if contact.id == @node_id

    bucket = find_closest_bucket(contact.id)
    duplicate_contact = bucket.find_contact_by_id(contact.id)

    if duplicate_contact
      duplicate_contact.update_last_seen
      return
    end

    if bucket.is_full?
      if bucket.is_splittable? && room_for_another_bucket? &&
         (node_is_closer(contact.id, bucket) ||
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
  def find_closest_bucket(id)
    idx = Binary.shared_prefix_bit_length(@node_id, id)
    buckets[idx] || buckets.last
  end

  def find_closest_contacts(id)
    closest_bucket = find_closest_bucket(id)
    results = [] + closest_bucket.contacts

    bucket_idx = @buckets.index(closest_bucket) - 1

    until results.size == ENV['k'] || bucket_idx < 0 do
      current_bucket = @buckets[bucket_idx]

      current_bucket.each do |contact|
        results.push(contact) if results.size < ENV['k'].to_i
      end

      bucket_idx -= 1
    end

    results
  end

  def node_is_closer(contact_id, bucket)
    Binary.shared_prefix_bit_length(@node_id, contact_id) > @buckets.index(bucket)
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