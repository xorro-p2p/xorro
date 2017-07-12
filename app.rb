require_relative 'node'
require_relative 'routing_table'
require_relative 'kbucket'
require_relative 'contact'

node = Node.new
rtable = RoutingTable.new(node)

puts rtable.buckets.first.is_full?
neighbor = Node.new
rtable.insert(neighbor)
puts rtable.buckets.first.contacts
