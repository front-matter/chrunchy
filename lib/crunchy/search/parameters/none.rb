require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # Just a standard boolean storage, except the rendering logic.
      #
      # @see Crunchy::Search::Parameters::BoolStorage
      # @see Crunchy::Search::Request#none
      # @see https://en.wikipedia.org/wiki/Null_Object_pattern
      class None < Storage
        include BoolStorage

        # Renders `match_none` query if the values is set to true.
        #
        # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html#query-dsl-match-none-query
        # @see Crunchy::Search::Request
        # @see Crunchy::Search::Request#response
        def render
          {query: {match_none: {}}} if value.present?
        end
      end
    end
  end
end
