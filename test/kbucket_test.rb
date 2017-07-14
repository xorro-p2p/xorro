require_relative 'test_helper.rb'
require_relative '../node.rb'
require_relative "../routing_table.rb"
require_relative "../kbucket.rb"
require_relative "../contact.rb"

class KBucketTest < Minitest::Test
  def setup
    @bucket = KBucket.new
    @node = Node.new('0')
    @options = {
      :id => @node.id,
      :ip => @node.ip,
    }
  end

  def test_create_bucket
    assert_instance_of(KBucket, @bucket)
    assert_equal([], @bucket.contacts)
    assert_equal(true, @bucket.splittable)
  end

  def test_add_contact
    @bucket.add(@options)

    assert_equal(1, @bucket.contacts.size)
  end

  def test_delete_contact
    @bucket.add(@options)
    @bucket.delete(@bucket.contacts[0])

    assert_equal(0, @bucket.contacts.size)
  end

  def test_delete_contact_that_is_not_included
    @bucket.add(@options)
    contact = Contact.new({ :id => '1', :ip => '' })
    @bucket.delete(contact)

    assert_equal(1, @bucket.contacts.size)
  end

  def test_head_tail_one_contact
    @bucket.add(@options)

    assert_equal(@bucket.contacts[0], @bucket.head)
    assert_equal(@bucket.contacts[0], @bucket.tail)
  end

  def test_head_tail_two_contacts
    @bucket.add(@options)
    @bucket.add({ :id => '1', :ip => '' })

    assert_equal(@bucket.contacts[0], @bucket.head)
    assert_equal(@bucket.contacts[1], @bucket.tail)
  end

  def test_bucket_is_full
    @bucket.add(@options)
    @bucket.add({ :id => '1', :ip => '' })

    assert(@bucket.is_full?)
  end

  def test_bucket_is_not_full
    @bucket.add(@options)

    refute(@bucket.is_full?)
  end

  def test_find_contact_by_id
    @bucket.add(@options)
    found_contact = @bucket.find_contact_by_id(@node.id)

    assert_equal(@bucket.contacts[0], found_contact)
  end

  def test_find_contact_by_id_no_match
    @bucket.add(@options)
    found_contact = @bucket.find_contact_by_id('1')

    assert_nil(found_contact)
  end

  def test_make_unsplittable
    @bucket.make_unsplittable

    refute(@bucket.splittable)
  end

  def test_is_redistributable
    @bucket.add({ :id => '15', :ip => '' })
    @bucket.add({ :id => '7', :ip => '' })

    node = Node.new('0')

    result = @bucket.is_redistributable?(node, 0)
    assert(result)
  end

  def test_is_not_redistributable
    @bucket.add({ :id => '15', :ip => '' })
    @bucket.add({ :id => '14', :ip => '' })

    node = Node.new('0')

    result = @bucket.is_redistributable?(node, 0)
    refute(result)
  end

  def test_sort_by_seen
    @bucket.add(@options)
    @bucket.add({ :id => '7', :ip => '' })

    @bucket.head.update_last_seen
    @bucket.sort_by_seen

    assert_equal('7', @bucket.head.id)
  end

  def test_attempt_eviction_pingable
    @bucket.add({ :id => '15', :ip => '' })
    @bucket.add({ :id => '14', :ip => '' })

    @bucket.attempt_eviction({ :id => '13', :ip => '' })

    assert_equal('15', @bucket.tail.id)
    assert_equal('14', @bucket.head.id)
  end

  def test_attempt_eviction_not_pingable
    @bucket.add({ :id => '15', :ip => '' })
    @bucket.add({ :id => '14', :ip => '' })

    @bucket.head.pingable = false
    @bucket.attempt_eviction({ :id => '13', :ip => '' })

    assert_equal('13', @bucket.tail.id)
    assert_equal('14', @bucket.head.id)
  end
end