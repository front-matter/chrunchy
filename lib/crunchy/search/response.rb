module Crunchy
  module Search
    # This class is a ES response hash wrapper.
    #
    # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/_the_search_api.html
    class Response
      # @param body [Hash] response body hash
      # @param loader [Crunchy::Search::Loader] loader instance
      def initialize(body, loader, paginator = nil)
        @body = body
        @loader = loader
        @paginator = paginator
      end

      # Raw response `hits` collection. Returns empty array is something went wrong.
      #
      # @return [Array<Hash>]
      def hits
        @hits ||= hits_root['hits'] || []
      end

      # Response `total` field. Returns `0` if something went wrong.
      #
      # @return [Integer]
      def total
        @total ||= hits_root.fetch('total', {}).fetch('value', 0)
      end

      # Response `max_score` field.
      #
      # @return [Float]
      def max_score
        @max_score ||= hits_root['max_score']
      end

      # Duration of the request handling in ms according to ES.
      #
      # @return [Integer]
      def took
        @took ||= @body['took']
      end

      # Has the request been timed out?
      #
      # @return [true, false]
      def timed_out?
        @timed_out ||= @body['timed_out']
      end

      # The `suggest` response part. Returns empty hash if suggests
      # were not requested.
      #
      # @return [Hash]
      def suggest
        @suggest ||= @body['suggest'] || {}
      end

      # The `aggregations` response part. Returns empty hash if aggregations
      # were not requested.
      #
      # @return [Hash]
      def aggs
        @aggs ||= @body['aggregations'] || {}
      end
      alias_method :aggregations, :aggs

      # {Crunchy::Index} wrappers collection instantiated on top of hits.
      #
      # @return [Array<Crunchy::Index>]
      def wrappers
        @wrappers ||= hits.map do |hit|
          @loader.derive_index(hit['_index']).build(hit)
        end
      end

      # ORM/ODM objects that had been a source for Crunchy import
      # and now loaded from the DB using hits ids. Uses
      # {Crunchy::Search::Request#load} passed options for loading.
      #
      # @see Crunchy::Search::Request#load
      # @see Crunchy::Search::Loader
      # @return [Array<Object>]
      def objects
        @objects ||= begin
          objects = @loader.load(hits)
          if @paginator
            @paginator.call(objects)
          else
            objects
          end
        end
      end
      alias_method :records, :objects
      alias_method :documents, :objects

      # This method is used in cases when you need to iterate through
      # both of the collections simultaneously.
      #
      # @example
      #   scope.each do |wrapper|
      #     scope.object_hash[wrapper]
      #   end
      # @see #wrappers
      # @see #objects
      # @return [{Crunchy::Index => Object}] a hash with wrappers as keys and ORM/ODM objects as values
      def object_hash
        @object_hash ||= wrappers.zip(objects).to_h
      end
      alias_method :record_hash, :object_hash
      alias_method :document_hash, :object_hash

    private

      def hits_root
        @body.fetch('hits', {})
      end
    end
  end
end
