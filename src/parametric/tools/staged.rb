module Parametric
  module Tools
    module Staged
      def self.included(cls)
        cls.extend ClassMethods 
      end

      private

      def active_stage
        stages.last
      end

      def next_stage(stage)
        try stage, :activate
        stages << stage
      end

      # Tries to undo the stages changes by sequentially calling
      # the #undo method for each item from the stages stack
      # NOTE: the STAGE #undo method should return the logical truth if the changes have been undone
      # @return [Object, nil] the stage where the undo method returned the logical truth
      def undo
        return if stages.empty?

        try(active_stage, :undo) || previous_stage_undo
      end

      def previous_stage_undo
        pop_stage
        undo
      end

      def pop_stage
        stage = stages.pop
        try stage, :deactivate
        try stage, :reset
      end

      def stages
        @stages ||= []
      end

      def try(receiver, method, *params)
        receiver.public_send(method, *params) if receiver.respond_to? method
      end

      module ClassMethods
        def staged_methods(*methods)
          shim = Module.new
          methods.each do |method_name|
            shim.define_method(method_name) do |*args|
              active_stage.public_send(method_name, *args) if active_stage&.respond_to? method_name
            end
          end
          self.include shim
        end
      end
    end
  end
end
