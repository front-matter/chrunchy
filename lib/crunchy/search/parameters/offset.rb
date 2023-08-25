require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard integer value storage, nothing to see here.
      #
      # @see Crunchy::Search::Parameters::IntegerStorage
      # @see Crunchy::Search::Request#offset
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-request-from-size.html
      class Offset < Storage
        include IntegerStorage
        self.param_name = :from
      end
    end
  end
end
