require 'minitest/autorun'
require 'minitest/reporters'
ENV['uploads'] = "~/Desktop"
ENV['bit_length'] = "6"
ENV['k'] = "2"
ENV['alpha'] = "1"
ENV['node_homes'] = ""

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]
