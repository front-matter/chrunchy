require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard integer value storage, nothing to see here.
      #
      # @see Crunchy::Search::Parameters::IntegerStorage
      # @see Crunchy::Search::Request#terminate_after
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-request-body.html
      class TerminateAfter < Storage
        include IntegerStorage
      end
    end
  end
end
