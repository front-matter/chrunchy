require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard integer value storage, nothing to see here.
      #
      # @see Crunchy::Search::Parameters::IntegerStorage
      # @see Crunchy::Search::Request#limit
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-request-from-size.html
      class Limit < Storage
        include IntegerStorage
        self.param_name = :size
      end
    end
  end
end
