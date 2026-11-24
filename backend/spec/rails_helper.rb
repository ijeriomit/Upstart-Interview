ENV["RAILS_ENV"] ||= "test"
abort "RSpec requires the Rails test environment" unless ENV["RAILS_ENV"] == "test"

require_relative "../config/environment"
require "rspec/rails"

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
end
