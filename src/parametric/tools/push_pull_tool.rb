module Parametric
  module Tools
    module PushPullTool
      attr_writer :profile

      def self.as_stage(profile, &when_done)
        Stage.new(profile, &when_done)
      end

      def activate
        @mouse = Sketchup::InputPoint.new
        @model = Model.new @profile
        update_ui
      end

      def draw(view)
        view.draw(GL_LINE_LOOP, @model.profile)
        if @model.vector&.valid?
          opposite = @model.profile.map { |point| point + @model.vector }
          view.draw(GL_LINE_LOOP, opposite)
          view.draw(GL_LINES, @model.profile.zip(opposite).flatten)
        end

        if @mouse.display?
          @mouse.draw(view)
          view.line_stipple = '-'
          view.draw(GL_LINES, @mouse.position, @model.profile.center + @model.vector)
        end
      end

      def getExtents
        ::Geom::BoundingBox.new.tap do |bb|
          bb.add @model.profile
          bb.add @model.profile.map { |point| point + @model.vector }
        end
      end

      def enableVCB?
        true
      end

      def onLButtonDown(flags, x, y, view)
        done(view) if @model.vector&.valid?
      end

      def onMouseMove(flags, x, y, view)
        @mouse.pick(view, x, y)
        # capture push pull vector
        @model.vector = if @mouse.display? # есть привязка к вершине, плоскости, ребру, направляющей
          p1 = @mouse.position
          p0 = p1.project_to_plane @model.profile.plane
          p0.vector_to p1
        else
          pickray = view.pickray(x, y)
          intersection = @model.test_plane.intersect(pickray)
          intersection.project_to_plane(@model.profile.plane).vector_to(intersection)
        end
        view.tooltip = @mouse.tooltip
        update_ui
        update_vcb_value
        view.invalidate
      end

      def onUserText(text, view)
        len = text.to_l
        return view.tooltip = 'Zero length' if len == 0

        if @model.vector.valid?
          @model.vector.length = len
          done(view)
        else
          view.tooltip = 'The direction is uncertain'
        end
      rescue ArgumentError
        view.tooltip = 'Invalid length value'
      end

      private

      def done(view)
        raise NotImplementedError, "heritors responsibility"
      end

      def update_ui
        Sketchup.status_text = 'Click to set box height or enter distance'
        Sketchup.vcb_label = 'Distance:'
      end

      def update_vcb_value
        Sketchup.vcb_value = @model.vector.length.to_s
      end

      class Model

        attr_accessor :vector, :profile

        def initialize(profile)
          @profile = Geom::Polygon.new profile
        end

        def test_plane
          @test_plane ||= begin
            p0 = @profile.vertices.first
            p1 = @profile.center
            Geom::Plane.new [p0, p1, p1.offset(@profile.plane.normal)]
          end
        end
      end

      class Stage
        include PushPullTool

        def initialize(profile, &when_done)
          @profile = profile
          @when_done = when_done
        end

        def done(view)
          @when_done.call({ view:, vector: @model.vector }) if @when_done&.respond_to?(:call)
          view.invalidate
        end
      end
    end
  end
end
