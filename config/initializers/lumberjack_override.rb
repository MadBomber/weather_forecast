# frozen_string_literal: true

# console-adapter-rails (pulled in by falcon-rails) installs itself as
# config.logger before lumberjack_rails can run, causing lumberjack_rails to
# bail out and leaving Console::Compatible::Logger as Rails.logger. That logger
# silently drops the structured attribute hash from calls like:
#
#   Rails.logger.info("weather.current", location: "London", cached: true)
#
# We replace Rails.logger here — after all railtie initializers have finished —
# so structured attributes are preserved and emitted as proper log fields.
#
# Device: falls back to $stderr (not $stdout) because Console gem — which
# produces the process_action.action_controller JSON lines — also writes to
# $stderr by default, so both output streams land in the same log file when
# Falcon is started with `> log/server.log 2>&1`.
#
# isolation_level: :fiber — Falcon (Async::Container::Forked) runs many
# concurrent fibers on the same OS thread. lumberjack_rails globally sets
# Lumberjack.isolation_level = :thread, which uses thread-local storage as
# the context scope key. That key is shared across all fibers on a thread,
# so when Fiber A sets locals.logging = true inside its write_to_device call
# and the async runtime context-switches to Fiber B, B's add_entry sees
# logging = true and silently drops the entry (the "prevent infinite
# recursion" guard). Using :fiber gives each fiber its own scope key via
# Fiber.current.object_id, isolating the guard correctly.
#
# In test we rely on CONSOLE_LEVEL=fatal (set in .env.test) silencing Console's
# output instead, keeping RSpec progress dots uncluttered. The test logger is
# left alone.

return if Rails.env.test?
return unless defined?(Lumberjack)

lj     = Rails.application.config.lumberjack
device = lj&.device || $stderr
level  = lj&.level || Rails.application.config.log_level || :debug

Rails.logger = Lumberjack::Logger.new(device, level: level, isolation_level: :fiber)
