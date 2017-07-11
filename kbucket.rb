class KBucket
  K = 4 # hardcoding k value for now
  attr_accessor :contacts

  def initialize
    @contacts = []
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

  end

  # split the bucket and redistribute contacts
  def split

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
    # sort @contacts -> oldest is head
    sort_by_seen

    if ping
      # update contact's last seen
      head.update_last_seen
    else
      # delete head
      delete(head)
      # insert new contact as tail
      add(hash)
    end
  end

  def ping
    true
  end

  def delete(contact)
    return unless @contacts.include? contact
    @contacts.delete contact
  end

  def sort_by_seen
    @contacts.sort_by(&:last_seen)
  end
end