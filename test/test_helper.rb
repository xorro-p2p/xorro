require 'minitest/autorun'
require 'minitest/reporters'
ENV['files'] = "~/Desktop"
ENV['shards'] = "~/Desktop"
ENV['manifests'] = "~/Desktop"
ENV['bit_length'] = "6"
ENV['k'] = "2"
ENV['alpha'] = "1"
ENV['development'] = "true"

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]
