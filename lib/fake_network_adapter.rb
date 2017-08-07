class FakeNetworkAdapter
  attr_reader :nodes

  def initialize
    @nodes = []
  end

  def get_node_by_contact(contact)
    @nodes.find { |n| n.id == contact.id }
  end

  def store(file_id, address, recipient_contact, sender_contact)
    recipient_node = get_node_by_contact(recipient_contact)
    recipient_node.receive_store(file_id, address, sender_contact)
    node = get_node_by_contact(sender_contact)
    node.ping(recipient_contact)
    nil
  end

  def find_node(query_id, recipient_contact, sender_contact)
    recipient_node = get_node_by_contact(recipient_contact)
    closest_nodes = recipient_node.receive_find_node(query_id, sender_contact)
    node = get_node_by_contact(sender_contact)
    node.ping(recipient_contact)

    closest_nodes
  end

  def find_value(file_id, recipient_contact, sender_contact)
    recipient_node = get_node_by_contact(recipient_contact)
    node = get_node_by_contact(sender_contact)
    node.ping(recipient_contact)
    recipient_node.receive_find_value(file_id, sender_contact)
  end

  def get_info
    nil
  end

  def ping(contact, sender_contact)
    recipient_node = get_node_by_contact(contact)

    if recipient_node
      recipient_node.receive_ping(sender_contact)
      contact.update_last_seen
      return true
    else
      return false
    end
  end

  def check_resource_status(_address)
    200
  end
end
