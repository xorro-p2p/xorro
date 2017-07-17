class NetworkAdapter
  attr_accessor :nodes
  
  def initialize
    @nodes = []
  end

  def get_node_by_contact(contact)
    @nodes.find {|n| n.id == contact.id }
  end

  # def ping(recipient_id, sender_contact)
  #   recipient_node = @nodes.find {|n| n.id == recipient_id }

  #   if recipient_node
  #     recipient_node.receive_ping(sender_contact)
  #   end
  #   recipient_node
  # end
end



