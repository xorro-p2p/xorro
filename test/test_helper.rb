require 'minitest/autorun'
require 'minitest/reporters'
ENV['uploads'] = "~/Desktop"

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]
