require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard hash storage. Nothing to see here.
      #
      # @see Crunchy::Search::Parameters::HashStorage
      # @see Crunchy::Search::Request#suggest
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-suggesters.html
      class Suggest < Storage
        include HashStorage
      end
    end
  end
end
