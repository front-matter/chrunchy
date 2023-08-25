require 'crunchy/search/scoping'
require 'crunchy/search/scrolling'
require 'crunchy/search/query_proxy'
require 'crunchy/search/parameters'
require 'crunchy/search/response'
require 'crunchy/search/loader'
require 'crunchy/search/request'
require 'crunchy/search/pagination/kaminari'

module Crunchy
  # This module being included to any provides an interface to the
  # request DSL. By default it is included to {Crunchy::Index}.
  #
  # The class used as a request DSL provider is
  # inherited from {Crunchy::Search::Request}
  #
  # Also, the search class is refined with the pagination module {Crunchy::Search::Pagination::Kaminari}.
  #
  # @example
  #   PlacesIndex.query(match: {name: 'Moscow'})
  # @see Crunchy::Index
  # @see Crunchy::Search::Request
  # @see Crunchy::Search::ClassMethods
  # @see Crunchy::Search::Pagination::Kaminari
  module Search
    extend ActiveSupport::Concern

    module ClassMethods
      # This is the entry point for the request composition, however,
      # most of the {Crunchy::Search::Request} methods are delegated
      # directly as well.
      #
      # This method also provides an ability to use names scopes.
      #
      # @example
      #   PlacesIndex.all.limit(10)
      #   # is basically the same as:
      #   PlacesIndex.limit(10)
      # @see Crunchy::Search::Request
      # @see Crunchy::Search::Scoping
      # @return [Crunchy::Search::Request] request instance
      def all
        search_class.scopes.last || search_class.new(self)
      end

      # A simple way to execute search string query.
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/search-uri-request.html
      # @return [Hash] the request result
      def search_string(query, options = {})
        options = options.merge(all.render.slice(:index).merge(q: query))
        Crunchy.client.search(options)
      end

      # Delegates methods from the request class to the index class
      #
      # @example
      #   PlacesIndex.query(match: {name: 'Moscow'})
      ruby2_keywords def method_missing(name, *args, &block)
        if search_class::DELEGATED_METHODS.include?(name)
          all.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _)
        search_class::DELEGATED_METHODS.include?(name) || super
      end

    private

      def search_class
        @search_class ||= build_search_class(Crunchy.search_class)
      end

      def build_search_class(base)
        search_class = Class.new(base)

        delegate_scoped self, search_class, scopes
        const_set('Query', search_class)
      end

      def delegate_scoped(source, destination, methods)
        methods.each do |method|
          destination.class_eval do
            define_method method do |*args, &block|
              scoping { source.public_send(method, *args, &block) }
            end
            ruby2_keywords method
          end
        end
      end
    end
  end
end
