require_relative 'development.rb'

class KBucket
  K = ENV['k'].to_i # hardcoding k value for now
  attr_reader :splittable
  attr_accessor :contacts

  def initialize
    @contacts = []
    @splittable = true
  end

  # implement the each method for our custom Node object
  include Enumerable
  def each(&block)
    @contacts.each(&block)
  end

  # candidate for removal if new contact is being added to a full bucket
  def head
    @contacts.first
  end

  def tail
    @contacts.last
  end

  # can rename this to depth
  # what is the number of shared leading bits of all contacts in this bucket?
  # def shared_bits_length()

  # end

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

  def is_redistributable?(node, index)
    shared_bit_lengths = @contacts.map do |c|
      # contacts and nodes both have IDs so they both can be passed into this method
      node.shared_prefix_bit_length(c)
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
  def add(hash)
    @contacts.push Contact.new(hash)
  end

  def attempt_eviction(hash)
    if head.pingable
      # update contact's last seen
      head.update_last_seen
      sort_by_seen
    else
      # delete head
      delete(head)
      # insert new contact as tail
      add(hash)
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
