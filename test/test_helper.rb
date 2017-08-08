require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/defaults.rb'
Defaults::ENVIRONMENT[:files] = "/dev/null"
Defaults::ENVIRONMENT[:shards] = "/dev/null"
Defaults::ENVIRONMENT[:manifests] = "/dev/null"
Defaults::ENVIRONMENT[:bit_length] = 6
Defaults::ENVIRONMENT[:k] = 2
Defaults::ENVIRONMENT[:alpha] = 1
Defaults::ENVIRONMENT[:test] = true

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]
