module Crunchy
  class Index
    module Observe
      module Helpers
        def update_proc(index_name, *args, &block)
          options = args.extract_options!
          method = args.first

          proc do
            reference = if index_name.is_a?(Proc)
              if index_name.arity.zero?
                instance_exec(&index_name)
              else
                index_name.call(self)
              end
            else
              index_name
            end

            index = Crunchy.derive_name(reference)

            next if Crunchy.strategy.current.name == :bypass

            backreference = if method && method.to_s == 'self'
              self
            elsif method
              send(method)
            else
              instance_eval(&block)
            end

            index.update_index(backreference, options)
          end
        end

        def extract_callback_options!(args)
          options = args.extract_options!
          result = options.each_key.with_object({}) do |key, hash|
            hash[key] = options.delete(key) if %i[if unless].include?(key)
          end
          args.push(options) unless options.empty?
          result
        end
      end

      extend Helpers

      module ActiveRecordMethods
        extend ActiveSupport::Concern

        def run_crunchy_callbacks
          crunchy_callbacks.each { |callback| callback.call(self) }
        end

        def update_crunchy_indices
          Crunchy.strategy.current.update_crunchy_indices(self)
        end

        included do
          class_attribute :crunchy_callbacks, default: []
        end

        class_methods do
          def initialize_crunchy_callbacks
            if Crunchy.use_after_commit_callbacks
              after_commit :update_crunchy_indices, on: %i[create update]
              after_commit :run_crunchy_callbacks, on: :destroy
            else
              after_save :update_crunchy_indices
              after_destroy :run_crunchy_callbacks
            end
          end

          ruby2_keywords def update_index(type_name, *args, &block)
            callback_options = Observe.extract_callback_options!(args)
            update_proc = Observe.update_proc(type_name, *args, &block)
            callback = Crunchy::Index::Observe::Callback.new(update_proc, callback_options)

            initialize_crunchy_callbacks if crunchy_callbacks.empty?

            self.crunchy_callbacks = crunchy_callbacks.dup << callback
          end
        end
      end
    end
  end
end
