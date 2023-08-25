require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard string value storage, nothing to see here.
      #
      # @see Crunchy::Search::Parameters::StringStorage
      # @see Crunchy::Search::Request#timeout
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/common-options.html#time-units
      class Timeout < Storage
        include StringStorage
      end
    end
  end
end
