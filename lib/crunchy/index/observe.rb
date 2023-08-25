require 'crunchy/index/observe/callback'
require 'crunchy/index/observe/active_record_methods'

module Crunchy
  class Index
    module Observe
      extend ActiveSupport::Concern

      module ClassMethods
        def update_index(objects, options = {})
          Crunchy.strategy.current.update(self, objects, options)
          true
        end
      end
    end
  end
end
