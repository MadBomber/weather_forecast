# Coverage must be started before any application code is loaded.
require "simplecov"
SimpleCov.start "rails" do
  minimum_coverage 80
  minimum_coverage_by_file 60
  add_filter "/spec/"
  add_filter "/config/"
  add_group "Controllers", "app/controllers"
  add_group "Services",    "app/services"
  add_group "Models",      "app/models"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Limit runs to :focus-tagged examples when any exist; run all otherwise.
  config.filter_run_when_matching :focus

  # Persist example status so --only-failures and --next-failure work.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Randomise order to surface ordering dependencies.
  config.order = :random
  Kernel.srand config.seed
end
