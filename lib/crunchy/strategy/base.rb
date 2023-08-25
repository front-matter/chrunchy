module Crunchy
  class Strategy
    # This strategy raises exception on every index update
    # asking to choose some other strategy.
    #
    #   Crunchy.strategy(:base) do
    #     User.all.map(&:save) # Raises UndefinedUpdateStrategy exception
    #   end
    #
    class Base
      def name
        self.class.name.demodulize.underscore.to_sym
      end

      # This method called when some model tries to update index
      #
      def update(type, _objects, _options = {})
        raise UndefinedUpdateStrategy, type
      end

      # This method called when strategy pops from the
      # strategies stack
      #
      def leave; end

      # This method called when some model record is created or updated.
      # Normally it will just evaluate all the Crunchy callbacks and pass results
      # to current strategy's update method.
      # However it's possible to override it to achieve delayed evaluation of
      # callbacks, e.g. using sidekiq.
      #
      def update_crunchy_indices(object)
        object.run_crunchy_callbacks
      end
    end
  end
end
