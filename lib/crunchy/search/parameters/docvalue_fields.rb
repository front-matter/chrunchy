require 'crunchy/search/parameters/storage'

module Crunchy
  module Search
    class Parameters
      # @see Crunchy::Search::Parameters::StringArrayStorage
      class DocvalueFields < Storage
        include StringArrayStorage
      end
    end
  end
end
