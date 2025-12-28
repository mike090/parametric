require_relative 'staged'

module Parametric
  module Tools
    # helps to define a virtual box
    module BoxTool
      include Staged
      def self.as_stage(&when_done)
        Stage.new(&when_done)
      end

      def self.use
        tool = as_stage { |box_params| puts box_params }
        Sketchup.active_model.select_tool tool
        Sketchup.focus
        tool
      end

      class Stage
        include BoxTool

        def initialize(&when_done)
          @when_done = when_done
        end

        def done(view)
          @when_done.call(@model) if @when_done&.respond_to? :call
          view.invalidate
        end
      end

      def activate
        run
      end

      private

      def run
        using :decomposition_tool do |xyz_result|
          @model = xyz_result
          if three_dim?
            done(@model.fetch :view)
          else
            profile = Geom::Rectangle.new(*@model.fetch_values(:vertex,:vectors).flatten).to_a
            using :push_pull_tool, profile do |push_pull_result|
              @model[:vectors][2] = push_pull_result[:vector]
              done(push_pull_result.fetch :view)
            end
          end
        end
      end

      def done(view)
        raise NotImplementedError, "heritors responsibility"
      end

      def three_dim?
        @model[:vectors].count == 3
      end
    end
  end
end
