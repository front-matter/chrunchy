require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard boolean storage, nothing to see here.
      #
      # @see Crunchy::Search::Parameters::BoolStorage
      # @see Crunchy::Search::Request#track_scores
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/search-request-sort.html#_track_scores
      class TrackScores < Storage
        include BoolStorage
      end
    end
  end
end
