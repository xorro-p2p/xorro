class NetworkAdapter
  attr_accessor :nodes
  
  def initialize
    @nodes = []
  end

  def get_node_by_contact(contact)
    @nodes.find {|n| n.id == contact.id }
  end
end



