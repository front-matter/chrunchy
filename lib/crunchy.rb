require 'active_support/version'
require 'active_support/concern'
require 'active_support/deprecation'
require 'active_support/json'
require 'active_support/log_subscriber'

require 'active_support/isolated_execution_state' if ActiveSupport::VERSION::MAJOR >= 7
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/inclusion'
require 'active_support/core_ext/string/inflections'

require 'singleton'
require 'base64'

require 'elasticsearch'

def try_require(path)
  require path
rescue LoadError
  nil
end

try_require 'kaminari'
try_require 'kaminari/core'
try_require 'parallel'

ActiveSupport.on_load(:active_record) do
  try_require 'kaminari/activerecord'
end

require 'crunchy/version'
require 'crunchy/errors'
require 'crunchy/config'
require 'crunchy/rake_helper'
require 'crunchy/repository'
require 'crunchy/runtime'
require 'crunchy/log_subscriber'
require 'crunchy/strategy'
require 'crunchy/index'
require 'crunchy/fields/base'
require 'crunchy/fields/root'
require 'crunchy/journal'
require 'crunchy/railtie' if defined?(::Rails::Railtie)

ActiveSupport.on_load(:active_record) do
  include Crunchy::Index::Observe::ActiveRecordMethods
end

module Crunchy
  @adapters = [
    Crunchy::Index::Adapter::ActiveRecord,
    Crunchy::Index::Adapter::Object
  ]

  class << self
    attr_accessor :adapters

    # A thread-local variables accessor
    # @return [Hash]
    def current
      unless Thread.current.thread_variable?(:crunchy)
        Thread.current.thread_variable_set(:crunchy, {})
      end

      Thread.current.thread_variable_get(:crunchy)
    end

    # Derives an index for the passed string identifier if possible.
    #
    # @example
    #   Crunchy.derive_name(UsersIndex) # => UsersIndex
    #   Crunchy.derive_name('namespace/users') # => Namespace::UsersIndex
    #   Crunchy.derive_name('missing') # => raises Crunchy::UndefinedIndex
    #
    # @param index_name [String, Crunchy::Index] index identifier or class
    # @raise [Crunchy::UndefinedIndex] in cases when it is impossible to find index
    # @return [Crunchy::Index]
    def derive_name(index_name)
      return index_name if index_name.is_a?(Class) && index_name < Crunchy::Index

      class_name = "#{index_name.camelize.gsub(/Index\z/, '')}Index"
      index = class_name.safe_constantize

      return index if index && index < Crunchy::Index

      raise Crunchy::UndefinedIndex, "Can not find index named `#{class_name}`"
    end

    # Main elasticsearch-ruby client instance
    #
    def client
      Crunchy.current[:crunchy_client] ||= begin
        client_configuration = configuration.deep_dup
        client_configuration.delete(:prefix) # used by Crunchy, not relevant to Elasticsearch::Client
        block = client_configuration[:transport_options].try(:delete, :proc)
        ::Elasticsearch::Client.new(client_configuration, &block)
      end
    end

    # Sends wait_for_status request to ElasticSearch with status
    # defined in configuration.
    #
    # Does nothing in case of config `wait_for_status` is undefined.
    #
    def wait_for_status
      if Crunchy.configuration[:wait_for_status].present?
        client.cluster.health wait_for_status: Crunchy.configuration[:wait_for_status]
      end
    end

    # Deletes all corresponding indexes with current prefix from ElasticSearch.
    # Be careful, if current prefix is blank, this will destroy all the indexes.
    #
    def massacre
      Crunchy.client.indices.delete(index: [Crunchy.configuration[:prefix], '*'].reject(&:blank?).join('_'))
      Crunchy.wait_for_status
    end
    alias_method :delete_all, :massacre

    # Strategies are designed to allow nesting, so it is possible
    # to redefine it for nested contexts.
    #
    #   Crunchy.strategy(:atomic) do
    #     city1.do_update!
    #     Crunchy.strategy(:urgent) do
    #       city2.do_update!
    #       city3.do_update!
    #       # there will be 2 update index requests for city2 and city3
    #     end
    #     city4..do_update!
    #     # city1 and city4 will be grouped in one index update request
    #   end
    #
    # It is possible to nest strategies without blocks:
    #
    #   Crunchy.strategy(:urgent)
    #   city1.do_update! # index updated
    #   Crunchy.strategy(:bypass)
    #   city2.do_update! # update bypassed
    #   Crunchy.strategy.pop
    #   city3.do_update! # index updated again
    #
    def strategy(name = nil, &block)
      Crunchy.current[:crunchy_strategy] ||= Crunchy::Strategy.new
      if name
        if block
          Crunchy.current[:crunchy_strategy].wrap name, &block
        else
          Crunchy.current[:crunchy_strategy].push name
        end
      else
        Crunchy.current[:crunchy_strategy]
      end
    end

    def config
      Crunchy::Config.instance
    end
    delegate(*Crunchy::Config.delegated, to: :config)

    def repository
      Crunchy::Repository.instance
    end
    delegate(*Crunchy::Repository.delegated, to: :repository)

    def create_indices
      Crunchy::Index.descendants.each(&:create)
    end

    def create_indices!
      Crunchy::Index.descendants.each(&:create!)
    end

    def eager_load!
      return unless defined?(Crunchy::Railtie)

      dirs = Crunchy::Railtie.all_engines.map do |engine|
        engine.paths[Crunchy.configuration[:indices_path]]
      end.compact.map(&:existent).flatten.uniq

      dirs.each do |dir|
        Dir.glob(File.join(dir, '**/*.rb')).each do |file|
          require_dependency file
        end
      end
    end
  end
end

require 'crunchy/stash'
