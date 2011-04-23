require 'rspec'
require 'wrong/adapters/rspec'
RSpec.configure do |config|
  config.mock_with :mocha
end