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

  # find the bucket to split and call split function
  def split_bucket(bucket)

  end

  # insert a new node into one of the k-buckets
  def insert(node)
    raise ArgumentError, 'cannot add self' if node == @node

    # bucket = find_matching_bucket(node)
    bucket = @buckets.first

    if bucket.is_full?
      if bucket.is_splittable?

      end
    else
      bucket.add(node)
    end
  end

  # find the bucket that has the matching/closest XOR distance
  def find_matching_bucket(node)
    
  end

  # delete a node from a bucket
  def delete(node)

  end
end