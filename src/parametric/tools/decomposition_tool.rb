require_relative '../geom'

module Parametric
  module Tools
    module DecompositionTool
      def self.as_stage(transformation = IDENTITY, &when_done)
        Stage.new(transformation, &when_done)
      end

      def self.use(transformation = IDENTITY)
        tool = as_stage(transformation) { |params| tool.reset; params[:view].invalidate }
        Sketchup.active_model.select_tool tool
        Sketchup.focus
        tool
      end

      attr_accessor :transformation

      def activate
        reset
      end

      def draw(view)
        @mouse.draw(view) if @mouse.display?

        case @model.vectors.count
        when 1
          view.draw GL_LINES, @model.start, @model.end
        when 2
          v1, v2 = @model.vectors
          p0 = @model.start
          view.draw GL_LINE_LOOP, [p0, p0 + v1, p0 + v1 + v2, p0 + v2]
        when 3
          v1, v2, v3 = @model.vectors
          p0 = @model.start
          loop = p0, p0 + v1, p0 + v1 + v2, p0 + v2
          view.draw GL_LINE_LOOP, loop
          opposite = loop.map { |point| point + v3 }
          view.draw GL_LINE_LOOP, opposite
          view.draw GL_LINES, loop.zip(opposite).flatten
        end
      end

      def getExtents
        ::Geom::BoundingBox.new.tap do |bb|
          bb.add @model.start if @model.start
          bb.add @model.end if @model.end
        end
      end

      def enableVCB?
        @model.start
      end

      def onCancel(reason, view)
        if @model.start
          @model.start = nil
          view.invalidate
          update_ui
        end
      end

      def onLButtonDown(flags, x, y, view)
        if @model.start
          @model.valid? ? done(view) : view.tooltip = 'invalid position'
        elsif @mouse.valid?
          @model.start = @mouse.position
          update_ui
        end
      end

      def onMouseMove(flags, x, y, view)
        @mouse.pick(view, x, y)
        if @model.start
          @model.end = calculate_end_point
          update_vcb_value
        end
        view.tooltip = @mouse.tooltip
        view.invalidate
      end

      def onUserText(text, view)
        len_vals = text.split(';').map(&:to_l)
        xyz = @model.vectors
        return view.tooltip = 'Incorrect dimensions count' unless
          len_vals.count == xyz.count

        xyz.zip(len_vals).map! do |vector, len|
          vector.length = len
          vector
        end
        @model.end = @model.start + xyz.reduce(&:+)

        if @model.vectors.count == 1
          view.tooltip = 'Corners on the same line'
        else
          done(view)
        end
      rescue ArgumentError
        view.tooltip = 'Invalid length value'
      end

      def resume(view)
        update_ui
        update_vcb_value
      end

      def reset
        @mouse = Sketchup::InputPoint.new
        @model = Model.new(@transformation || IDENTITY)
        update_ui
        update_vcb_value
      end

      private

      def calculate_end_point
        @model.end = @mouse.position
      end

      def done(view)
        raise NotImplementedError, "heritors responsibility"
      end

      def update_ui
        Sketchup.status_text = @model.start ? 'Click to set opposite corner or enter dimensions' : 'Click to set first point'
        Sketchup.vcb_label = 'Dimensions:'
      end

      def update_vcb_value
        Sketchup.vcb_value = @model.vectors.map(&:length).map(&:to_s).join(';')
      end

      class Model
        attr_accessor :start, :end

        def initialize(transformation)
          @transformation = transformation
        end

        def vectors
          return [] unless @start && @end

          xyz = @start.vector_to(@end)
          xyz.transform! @transformation
          Geom.decompose_vector(xyz).map { |vector| vector.transform @transformation.inverse }
        end

        def valid?
          vectors.count > 1
        end
      end

      class Stage
        include DecompositionTool

        def initialize(transformation = IDENTITY, &when_done)
          @transformation = transformation
          @when_done = when_done
        end

        private

        def done(view)
          @when_done.call({ view:, vertex: @model.start, vectors: @model.vectors }) if @when_done&.respond_to?(:call)
          view.invalidate
        end
      end
    end
  end
end
