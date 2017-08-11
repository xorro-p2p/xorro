require_relative 'defaults.rb'
require_relative 'binary.rb'

class KBucket
  attr_reader :splittable, :contacts, :node

  def initialize(node)
    @node = node
    @contacts = []
    @splittable = true
  end

  include Enumerable
  def each
    @contacts.each do |c|
      yield c
    end
  end

  # candidate for removal if new contact is being added to a full bucket
  def head
    @contacts.first
  end

  def tail
    @contacts.last
  end

  def full?
    @contacts.size == Defaults::ENVIRONMENT[:k]
  end

  # is this the bucket that has the longest shared_bits_length?
  def hasnt_been_split?
    @splittable
  end

  def find_contact_by_id(id)
    @contacts.find do |c|
      c.id == id
    end
  end

  def redistributable?(node_id, index)
    shared_bit_lengths = Binary.shared_prefix_bit_length_map(node_id, @contacts)

    has_moveable_value = shared_bit_lengths.any? do |bit_length|
      bit_length > index
    end

    has_moveable_value
  end

  def make_unsplittable
    @splittable = false
    @node.sync
  end

  def add(contact)
    @contacts.push contact
    @node.sync
  end

  def attempt_eviction(new_contact)
    if @node.ping(head)
      head.update_last_seen
      sort_by_seen
      @node.sync
    else
      delete(head)
      add(new_contact)
    end
  end

  def delete(contact)
    return unless @contacts.include? contact
    @contacts.delete contact
    @node.sync
  end

  def sort_by_seen
    @contacts.sort_by!(&:last_seen)
  end

  def size
    contacts.size
  end
end
