# frozen_string_literal: true

Before do
  # no-op
end

When('a step passes') do
  # no-op
end

When('a step fails') do
  raise 'Exception in step'
end

After do
  # no-op
end
