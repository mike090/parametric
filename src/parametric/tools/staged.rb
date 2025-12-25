module Parametric
  module Tools
    module Staged

      def respond_to?(symbol, include_all=false)
        super || @stage&.respond_to?(symbol)
      end

      def method_missing(symbol, *args)
        try @stage, symbol, *args
      end

      private

      def try(receiver, method, *args)
        receiver.public_send(method, *args) if receiver&.respond_to? method
      end

      def using(tool, *args, &block)
        tool = Tools.default(tool)
        use tool.as_stage(*args, &block)
      end

      def use (stage)
        try @stage, :deactivate, Sketchup.active_model.active_view
        @stage = stage
        try @stage, :activate
      end
    end
  end
end
