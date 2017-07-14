require_relative 'development.rb'
require_relative 'binary.rb'

class KBucket
  K = ENV['k'].to_i # hardcoding k value for now
  attr_reader :splittable
  attr_accessor :contacts

  def initialize
    @contacts = []
    @splittable = true
  end

  # candidate for removal if new contact is being added to a full bucket
  def head
    @contacts.first
  end

  def tail
    @contacts.last
  end

  def is_full?
    @contacts.size == K
  end

  # is this the bucket that has the longest shared_bits_length?
  def is_splittable?
    @splittable
  end

  def find_contact_by_id(id)
    @contacts.find do |c|
      c.id == id
    end
  end

  def is_redistributable?(node_id, index)
    shared_bit_lengths = @contacts.map do |c|
      Binary.shared_prefix_bit_length(node_id, c.id)
    end

    has_moveable_value = shared_bit_lengths.any? do |bit_length|
      bit_length > index
    end

    has_different_values = shared_bit_lengths.uniq.size > 1

    has_moveable_value && has_different_values
  end

  def make_unsplittable
    @splittable = false
  end

  # if this bucket already includes the contact, move existing contact to tail and discard new contact
  # if this bucket doesn't include the contact and @contacts.size < K, insert new contact as tail
  # if this bucket doesn't include the contact and bucket is full
  #   ping head; delete head if it doesn't respond and insert new contact as tail
  #              move head to tail end if it does respond, discard new contact
  def add(contact)
    @contacts.push contact
  end

  def attempt_eviction(contact)
    if head.pingable
      head.update_last_seen
      sort_by_seen
    else
      delete(head)
      # insert new contact as tail
      add(contact)
    end
  end

  def delete(contact)
    return unless @contacts.include? contact
    @contacts.delete contact
  end

  def sort_by_seen
    @contacts.sort_by!(&:last_seen)
  end
end
