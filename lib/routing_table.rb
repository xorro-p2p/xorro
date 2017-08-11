require_relative 'defaults.rb'
require_relative 'binary.rb'
require_relative 'kbucket.rb'

class RoutingTable
  attr_reader :node, :node_id, :buckets

  def initialize(current_node)
    @node = current_node
    @node_id = current_node.id
    @buckets = [KBucket.new(@node)]
  end

  def insert(contact)
    return if contact.id == @node_id

    bucket = find_closest_bucket(contact.id)
    duplicate_contact = bucket.find_contact_by_id(contact.id)

    if duplicate_contact
      duplicate_contact.update_last_seen
      @node.sync
      return
    end

    if bucket.full?
      process_full_bucket(bucket, contact)
    else
      bucket.add(contact)
    end
  end

  def find_closest_bucket(id)
    idx = Binary.shared_prefix_bit_length(@node_id, id)
    buckets[idx] || buckets.last
  end

  def find_closest_contacts(id, sender_contact = nil, quantity = Defaults::ENVIRONMENT[:k])
    closest_bucket = find_closest_bucket(id)
    results = []

    bucket_idx = @buckets.index(closest_bucket)
    further_bucket_idx = bucket_idx - 1

    fill_closest_contacts(results, bucket_idx, sender_contact, true, quantity)
    fill_closest_contacts(results, further_bucket_idx, sender_contact, false, quantity)

    results
  end

  def create_bucket
    buckets.push KBucket.new(@node)
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
      new_bucket.contacts.push(m)
    end
  end

  private

  def process_full_bucket(bucket, contact)
    if bucket_splittable?(bucket, contact)
      split(bucket)
      insert(contact)
    else
      bucket.attempt_eviction(contact)
    end
  end

  def fill_closest_contacts(results, start_idx, sender_contact, to_right_side, quantity)
    mover = to_right_side ? 1 : -1

    until results.size == quantity || start_idx == buckets.size || start_idx < 0
      current_bucket = @buckets[start_idx]

      current_bucket.each do |contact|
        ingest_contact(results, contact, quantity, sender_contact)
      end

      start_idx += mover
    end
  end

  def ingest_contact(results, contact, quantity, sender)
    if sender
      results.push(contact) if results.size < quantity && contact.id != sender.id
    elsif results.size < quantity
      results.push(contact)
    end
  end

  def bucket_splittable?(bucket, contact)
    bucket.hasnt_been_split? &&
      room_for_another_bucket? &&
      (node_is_closer(contact.id, bucket) || bucket.redistributable?(@node_id, @buckets.index(bucket)))
  end

  def node_is_closer(contact_id, bucket)
    Binary.shared_prefix_bit_length(@node_id, contact_id) > @buckets.index(bucket)
  end

  def room_for_another_bucket?
    buckets.size < Defaults::ENVIRONMENT[:bit_length]
  end

  def split(bucket)
    bucket.make_unsplittable
    create_bucket
    redistribute_contacts
    @node.sync
  end
end
