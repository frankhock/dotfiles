# frozen_string_literal: true

require_relative "../claude/scripts/ralph-loop"
require "tmpdir"
require "json"
require "fileutils"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end

# Build a RalphLoop instance with pre-set internal state, bypassing run/parse_options.
def build_ralph(overrides = {})
  loop_instance = RalphLoop.allocate
  loop_instance.send(:initialize)

  overrides.each do |ivar, value|
    loop_instance.instance_variable_set(:"@#{ivar}", value)
  end

  loop_instance
end

# Write a minimal ralph-tasks.json and prompt file into a tmpdir.
# Returns [tmpdir_path, prd_path, prompt_path].
def create_fixtures(tasks: [], project: "test-project", prompt_content: "do the thing", **prd_extras)
  dir = Dir.mktmpdir("ralph-spec-")

  prd = { "project" => project, "tasks" => tasks }.merge(prd_extras)
  prd_path = File.join(dir, "ralph-tasks.json")
  File.write(prd_path, JSON.pretty_generate(prd))

  prompt_path = File.join(dir, "ralph-prompt.md")
  File.write(prompt_path, prompt_content)

  # Some tests need CLAUDE.md to exist
  File.write(File.join(dir, "CLAUDE.md"), "# Test")

  [dir, prd_path, prompt_path]
end
