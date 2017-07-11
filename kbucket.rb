class KBucket
  K = 8 # hardcoding k value for now
  attr_accessor :nodes

  def initialize
    @nodes = []
  end

  # implement the each method for our custom Node object
  include Enumerable
  def each(&block)
    @nodes.each(&block)
  end

  # candidate for removal if new node is being added to a full bucket
  def head
    @nodes.first
  end

  def tail
    @nodes.last
  end

  # can rename this to depth
  # what is the number of shared leading bits of all nodes in this bucket?
  def shared_bits_length

  end

  def is_full?
    @nodes.size == K
  end

  # is this the bucket that has the longest shared_bits_length?
  def is_splittable?

  end

  # split the bucket and redistribute nodes
  def split

  end

  # if this bucket already includes the node, move existing node to tail and discard new node
  # if this bucket doesn't include the node and @nodes.size < K, insert new node as tail
  # if this bucket doesn't include the node and bucket is full
  #   ping head; delete head if it doesn't respond and insert new node as tail
  #              move head to tail end if it does respond, discard new node
  def add(node)
    @nodes.push node
  end

  def delete(node)
    return unless @nodes.include? node
    @nodes.delete node
  end

  def sort_by_seen

  end
end