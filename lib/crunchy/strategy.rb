require 'crunchy/strategy/base'
require 'crunchy/strategy/bypass'
require 'crunchy/strategy/urgent'
require 'crunchy/strategy/atomic'
require 'crunchy/strategy/atomic_no_refresh'

begin
  require 'sidekiq'
  require 'crunchy/strategy/sidekiq'
  require 'crunchy/strategy/lazy_sidekiq'
  require 'crunchy/strategy/delayed_sidekiq'
rescue LoadError
  nil
end

begin
  require 'active_job'
  require 'crunchy/strategy/active_job'
rescue LoadError
  nil
end

module Crunchy
  # This class represents strategies stack with `:base`
  # Strategy on top of it. This causes raising exceptions
  # on every index update attempt, so other strategy must
  # be choosen.
  #
  #   User.first.save # Raises UndefinedUpdateStrategy exception
  #
  #   Crunchy.strategy(:atomic) do
  #     User.last.save # Save user according to the `:atomic` strategy rules
  #   end
  #
  class Strategy
    def initialize
      @stack = [resolve(Crunchy.root_strategy).new]
    end

    def current
      @stack.last
    end

    def push(name)
      result = @stack.push resolve(name).new
      debug "[#{@stack.size - 1}] <- #{current.name}" if @stack.size > 2
      result
    end

    def pop
      raise "Can't pop root strategy" if @stack.one?

      result = @stack.pop.tap(&:leave)
      debug "[#{@stack.size}] -> #{result.name}, now #{current.name}" if @stack.size > 1
      result
    end

    def wrap(name)
      stack = push(name)
      yield
    ensure
      pop if stack
    end

  private

    def debug(string)
      return unless Crunchy.logger&.debug?

      line = caller.detect { |l| l !~ %r{lib/crunchy/strategy.rb:|lib/crunchy.rb:} }
      Crunchy.logger.debug(["Crunchy strategies stack: #{string}", line.sub(/:in\s.+$/, '')].join(' @ '))
    end

    def resolve(name)
      "Crunchy::Strategy::#{name.to_s.camelize}".safe_constantize or raise "Can't find update strategy `#{name}`"
    end
  end
end
