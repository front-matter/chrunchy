require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard hash storage. Nothing to see here.
      #
      # @see Crunchy::Search::Parameters::HashStorage
      # @see Crunchy::Search::Request#aggregations
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
      class Aggs < Storage
        include HashStorage
      end
    end
  end
end
