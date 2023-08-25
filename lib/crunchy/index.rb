require 'crunchy/search'
require 'crunchy/index/actions'
require 'crunchy/index/adapter/active_record'
require 'crunchy/index/adapter/object'
require 'crunchy/index/aliases'
require 'crunchy/index/crutch'
require 'crunchy/index/import'
require 'crunchy/index/mapping'
require 'crunchy/index/observe'
require 'crunchy/index/settings'
require 'crunchy/index/specification'
require 'crunchy/index/syncer'
require 'crunchy/index/witchcraft'
require 'crunchy/index/wrapper'

module Crunchy
  class Index
    IMPORT_OPTIONS_KEYS = %i[
      batch_size bulk_size consistency direct_import journal
      pipeline raw_import refresh replication
    ].freeze

    STRATEGY_OPTIONS = {
      delayed_sidekiq: %i[latency margin ttl reindex_wrapper]
    }.freeze

    include Search
    include Actions
    include Aliases
    include Import
    include Mapping
    include Observe
    include Crutch
    include Witchcraft
    include Wrapper

    singleton_class.delegate :client, to: 'Crunchy'

    class_attribute :adapter
    self.adapter = Crunchy::Index::Adapter::Object.new(:default)

    class_attribute :index_scope_defined

    class_attribute :_settings
    self._settings = Crunchy::Index::Settings.new

    class_attribute :_default_import_options
    self._default_import_options = {}

    class << self
      # @overload index_name(suggest)
      #   If suggested name is passed, it is set up as the new base name for
      #   the index. Used for the index base name redefinition.
      #
      #   @example
      #     class UsersIndex < Crunchy::Index
      #       index_name :legacy_users
      #     end
      #     UsersIndex.index_name # => 'legacy_users'
      #
      #   @param suggest [String, Symbol] suggested base name
      #   @return [String] new base name
      #
      # @overload index_name(prefix: nil, suffix: nil)
      #   If suggested name is not passed, returns the base name accompanied
      #   with the prefix (if any) and suffix (if passed).
      #
      #   @example
      #     class UsersIndex < Crunchy::Index
      #     end
      #
      #     Crunchy.settings = {prefix: 'test'}
      #     UsersIndex.index_name # => 'test_users'
      #     UsersIndex.index_name(prefix: 'foobar') # => 'foobar_users'
      #     UsersIndex.index_name(suffix: '2017') # => 'test_users_2017'
      #     UsersIndex.index_name(prefix: '', suffix: '2017') # => 'users_2017'
      #
      #   @param prefix [String] index name prefix, uses {.prefix} method by default
      #   @param suffix [String] index name suffix, used for creating several indexes for the same
      #     alias during the zero-downtime reset
      #   @raise [UndefinedIndex] if the base name is blank
      #   @return [String] result index name
      def index_name(suggest = nil, prefix: nil, suffix: nil)
        if suggest
          @base_name = suggest.to_s.presence
        else
          [
            prefix || self.prefix,
            base_name,
            suffix
          ].reject(&:blank?).join('_')
        end
      end

      # Base name for the index. Uses the default value inferred from the
      # class name unless redefined.
      #
      # @example
      #   class Namespace::UsersIndex < Crunchy::Index
      #   end
      #   UsersIndex.index_name # => 'users'
      #
      #   Class.new(Crunchy::Index).base_name # => raises UndefinedIndex
      #
      # @raise [UndefinedIndex] when the base name is blank
      # @return [String] current base name
      def base_name
        @base_name ||= name.sub(/Index\z/, '').demodulize.underscore if name
        raise UndefinedIndex if @base_name.blank?

        @base_name
      end

      # Similar to the {.base_name} but respects the class namespace, also,
      # can't be redefined. Used to reference index with the string identifier
      #
      # @example
      #   class Namespace::UsersIndex < Crunchy::Index
      #   end
      #   UsersIndex.derivable_name # => 'namespace/users'
      #
      #   Class.new(Crunchy::Index).derivable_name # => nil
      #
      # @return [String, nil] derivable name or nil when it is impossible to calculate
      def derivable_name
        @derivable_name ||= name.sub(/Index\z/, '').underscore if name
      end

      # Used as a default value for {.index_name}. Return prefix from the configuration
      # but can be redefined per-index to be more dynamic.
      #
      # @example
      #   class UsersIndex < Crunchy::Index
      #     def self.prefix
      #       'foobar'
      #     end
      #   end
      #   UsersIndex.index_name # => 'foobar_users'
      #
      # @return [String] prefix
      def prefix
        Crunchy.configuration[:prefix]
      end

      # Defines scope and options for the index. Arguments depends on adapter used. For
      # ActiveRecord you can pass model or scope and options
      #
      #   class CarsIndex < Crunchy::Index
      #     index_scope Car
      #     ...
      #   end
      #
      # For plain objects you can completely omit this directive, unless you need to specify some options:
      #
      #   class PlanesIndex < Crunchy::Index
      #     ...
      #   end
      #
      # The main difference between using plain objects or ActiveRecord models for indexing
      # is import. If you will call `CarsIndex.import` - it will import all the cars
      # automatically, while `PlanesIndex.import(my_planes)` requires import data to be
      # passed.
      #
      def index_scope(target, options = {})
        raise 'Index scope is already defined' if index_scope_defined?

        self.adapter = Crunchy.adapters.find { |klass| klass.accepts?(target) }.new(target, **options)
        self.index_scope_defined = true
      end

      # Used as a part of index definition DSL. Defines settings:
      #
      #   class UsersIndex < Crunchy::Index
      #     settings analysis: {
      #       analyzer: {
      #         name: {
      #           tokenizer: 'standard',
      #           filter: ['lowercase', 'icu_folding', 'names_nysiis']
      #         }
      #       }
      #     }
      #   end
      #
      # See http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-update-settings.html
      # for more details
      #
      # It is possible to store analyzers settings in Crunchy repositories
      # and link them form index class. See `Crunchy::Index::Settings` for details.
      #
      def settings(params = {}, &block)
        self._settings = Crunchy::Index::Settings.new(params, &block)
      end

      # Returns list of public class methods defined in current index
      #
      def scopes
        public_methods - Crunchy::Index.public_methods
      end

      def settings_hash
        _settings.to_hash
      end

      def mappings_hash
        mappings = root.mappings_hash
        mappings.present? ? {mappings: mappings} : {}
      end

      # Returns a hash containing the index settings and mappings
      # Used for the ES index creation as body.
      #
      # @see Crunchy::Index::Specification
      # @return [Hash] specification as a hash
      def specification_hash
        [settings_hash, mappings_hash].inject(:merge)
      end

      # @see Crunchy::Index::Specification
      # @return [Crunchy::Index::Specification] a specification object instance for this particular index
      def specification
        @specification ||= Specification.new(self)
      end

      def default_import_options(params)
        params.assert_valid_keys(IMPORT_OPTIONS_KEYS)
        self._default_import_options = _default_import_options.merge(params)
      end

      def strategy_config(params = {})
        @strategy_config ||= begin
          config_struct = Struct.new(*STRATEGY_OPTIONS.keys).new

          STRATEGY_OPTIONS.each_with_object(config_struct) do |(strategy, options), res|
            res[strategy] = case strategy
            when :delayed_sidekiq
              Struct.new(*STRATEGY_OPTIONS[strategy]).new.tap do |config|
                options.each do |option|
                  config[option] = params.dig(strategy, option) || Crunchy.configuration.dig(:strategy_config, strategy, option)
                end

                config[:reindex_wrapper] ||= ->(&reindex) { reindex.call } # default wrapper
              end
            else
              raise NotImplementedError, "Unsupported strategy: '#{strategy}'"
            end
          end
        end
      end
    end
  end
end
