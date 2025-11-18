module Parametric
  module Tools
    module Staged
      def self.included(cls)
        cls.extend ClassMethods 
      end

      private

      # Adds an active stage to the stages stack
      # Activates the stage
      # @return [Object, nil] 
      def stage
        return unless a_stage = define_stage

        unless stages.last == a_stage
          stages.push a_stage
          try a_stage, :activate
        end
        a_stage
      end

      # Tries to undo the stages changes by sequentially calling
      # the #undo method for each item from the stages stack
      # NOTE: the STAGE #undo method should return the logical truth if the changes have been undone
      # @return [Object, ] the stage where the undo method returned the logical truth
      def undo
        return if stages.empty?

        last_stage_undo || previous_stage_undo
        stages.last
      end

      def last_stage_undo
        try stages.last, :undo
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
              active_stage = stage
              active_stage.public_send(method_name, *args) if active_stage&.respond_to? method_name
            end
          end
          self.include shim
        end
      end
    end
  end
end
