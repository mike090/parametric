require_relative 'staged'
require_relative 'colors'
require_relative '../geom/box'

module Parametric
  module Tools
    class CabinetTool

      def self.use
        tool = new()
        Sketchup.active_model.select_tool tool
        Sketchup.focus
        tool
      end

      include Staged

      DEFAULT_PANEL_PARAMS = {
        thickness: 16.mm, offset: 0, shift: 0, outside_direction: false, external_bounds: false }.freeze

      def activate
        run
      end

      def onKeyDown(key, repeat, flags, view)
        case key
        when VK_ESCAPE
          run
        else
          try @stage, :onKeyDown, key, repeat, flags, view
        end
      end

      private

      def run
        using :box_tool  do |box_tool_result|
          box_params = box_tool_result.fetch_values(:vertex, :vectors).flatten
          stage = BuilderStage.new box_params
          use stage
        end
      end

      class BuilderStage
        attr_accessor :when_done

        def initialize(box_params)
          @box_params = box_params
        end

        def activate
          @model = Model.new *@box_params
          @mouse_ip = Sketchup::InputPoint.new
        end

        def resume(view)
          view.invalidate
        end

        def draw(view)
          draw_module_bounds(view)
          draw_targets(view)
          draw_panel_preview(view)
        end

        def getExtents
          @model.bounds
        end

        def onMouseMove(flags, x, y, view)
          @mouse_ip.pick(view, x, y)
          pickray = view.pickray(x, y)
          @model.pick pickray
          update_ui
          view.invalidate
        end

        def onLButtonDown(flags, x, y, view)
          if @model.focused
            create_panel
            return view.invalidate
          end

          ph = view.pick_helper
          if ph.do_pick(x, y)
            Sketchup.active_model.selection.clear
            Sketchup.active_model.selection.add ph.best_picked
          end
        end

        def onKeyDown(key, repeat, flags, view)
          case key
          when VK_SHIFT
            view.invalidate if private_panel_params&.toggle_direction
          when VK_CONTROL
            view.invalidate if private_panel_params&.toggle_external_bounds
          when VK_TAB
            params_accessor.next
            update_ui
          end
        end

        def onReturn(view)
          if @model.focused
            create_panel
            return view.invalidate
          end
        end

        def onUserText(text, view)
          if params_accessor.set(text)
            view.invalidate
            update_ui
          end
        rescue ArgumentError => e
          view.tooltip = e.message
        end

        def enableVCB?
          params_accessor&.prompt
        end

        private

        def params_accessor
          if @model.focused
            panel_params_accessor
          else
            default_params_accessor
          end
        end

        def panel_params_accessor
          @panel_params_accessor ||= begin
            accessor = CarouselParamsAccessor.new do |private|
              private ? private_panel_params : @model.focused.panel_params || default_panel_params
            end
            %i(thickness offset shift).each do |param|
              accessor.add LengthAccessor.new(param, "Panel #{param}:")
            end
            accessor
          end
        end

        def default_params_accessor
          @default_params_accessor ||= begin
            accessor = CarouselParamsAccessor.new { default_panel_params }
            accessor.add LengthAccessor.new :thickness, 'Default panel thickness:'
            accessor
          end
        end

        def update_ui
          Sketchup.vcb_label = params_accessor.prompt
          Sketchup.vcb_value = params_accessor.get.to_s

          if @model.focused
            Sketchup.status_text = 'Click to create panel | SHIFT to toggle direction | CTRL to toggle bounds | TAB to set panel params'
          else
            Sketchup.status_text = 'Select target to preview panel'
          end
        end

        def draw_module_bounds(view)
          view.drawing_color = Colors::MODULE_BOUNDS
          view.line_width = 1
          view.draw GL_LINES, @model.edges.flatten
        end

        def draw_targets(view)
          view.drawing_color = Colors::TARGET
          @model.available_targets.each do |target|
            next if @model.focused == target

            view.draw(GL_POLYGON, *target)
          end
        end

        def draw_panel_preview(view)
          preview = panel_preview
          return unless preview

          view.drawing_color = Colors::PANEL_PREVIEW_EDGES
          view.draw(GL_LINES, preview.edges.flatten)
          view.drawing_color = Colors::PANEL_PREVIEW
          preview.sides.each { |side| view.draw(GL_POLYGON, *side) }
        end

        def default_panel_params
          @default_panel_params ||= PanelCreationParams.new
        end

        def private_panel_params
          return unless @model.focused

          @model.focused.panel_params ||= default_panel_params.clone
        end

        def panel_preview
          return unless @model.focused&.available?

          params = @model.focused.panel_params || default_panel_params
          profile = @model.profile_bounds params.external_bounds
          profile.offset!(params.offset).shift!(params.shift)
          center = @model.bounds.center
          thickness_vector = center.project_to_plane(@model.focused.plane).vector_to(center)
          thickness_vector.reverse! if params.outside_direction
          thickness_vector.length = params.thickness
          Geom::Box.new *profile.params << thickness_vector
        end

        def create_panel
          Sketchup.active_model.start_operation 'Add panel'
          preview = panel_preview
          panel = builder.add_panel *preview.params
          @model.focused.panel = panel
          Sketchup.active_model.commit_operation
        end

        def builder
          @builder ||= CabinetBuilder.new *@box_params
        end
      end

      class PanelBuilder
        class << self
          def build(panel_params, entities)
            transformation = normalize_position(panel_params)

            panel_params.map! { |param| param.transform transformation.inverse }
            panel_model = Geom::Box.new *panel_params

            panel = entities.add_group
            panel.transformation = transformation

            panel_model.sides.each do |side|
              panel.entities.add_face *side
            end
            panel.name = 'panel'
            panel
          end

          private

          def normalize_position(params)
            origin, axes = params[0], params[1..]
            z, y, x = axes.sort_by(&:length)
            rtn_90 = ::Geom::Transformation.rotation origin, z, 90.degrees
            unless x.transform(rtn_90).samedirection? y
              origin.offset! y
              y.reverse!
            end
            ::Geom::Transformation.new(x,y,z,origin)
          end
        end
      end

      class CabinetBuilder
        def initialize(*cabinet_params)
          @transformation = define_position cabinet_params.map(&:clone)
        end

        def add_panel(*panel_params)
          transformation = @transformation.inverse
          PanelBuilder.build(
            panel_params.map { |param| param.transform transformation },
            cabinet.entities
          )
        end

        private

        def cabinet
          @cabinet ||= Sketchup.active_model.active_entities.add_group.tap do |cabinet|
            cabinet.transformation = @transformation
            cabinet.name = 'cabinet'
          end
        end

        def define_position(params)
          origin, vectors = params[0], params[1..]
          workspace = Sketchup.active_model.edit_transform
          axes = [workspace.xaxis, workspace.yaxis, workspace.zaxis]
          vectors = axes.map do |axis|
            vector = vectors.find { |vector| vector.parallel? axis }
            raise TypeError, "Expected cabinet's bounding edges must be parralel to the space axes" unless vector

            unless vector.samedirection? axis
              origin.offset! vector
              vector.reverse!
            end
            vector
          end
          ::Geom::Transformation.new *vectors, origin
        end
      end

      class Model
        extend Forwardable
        def_delegators :@box, :edges, :bounds
        attr_reader :focused

        # @param box_params [Array<Geom::Point3d, *[Geom::Vector3d] * 3>] a point and three vectors defining a box
        # @param skechup_model [Sketchup::Model] a sketchup model
        def initialize(*box_params)
          @box = Geom::Box.new *box_params
          @sketchup_model = Sketchup.active_model
        end

        # Returns targets on the sides of the virtual box
        def targets
          @targets ||= @box.sides.map { |side| Target.new side, '1/3' }
        end

        def available_targets
          targets.select(&:available?)
        end

        # The bounds defined by the bounds of the virtual box side, or the geometry of the model
        # @param external [Boolean] ignore the geometry of the model
        def profile_bounds(external = false)
          return nil unless @focused

          side = @focused.side
          return side.clone if external

          bounding_lines = side.edges
          bounding_lines.map! do |line|
            projection = @hit_point.project_to_line(line)
            ray = [@hit_point, @hit_point.vector_to(projection)]
            model_intersection = @sketchup_model.raytest(ray)
            next line unless model_intersection

            model_intersection_point = model_intersection.first
            [
              [projection, line],
              [model_intersection_point, [model_intersection_point, line.reduce(&:-)]]
            ].min_by { |point, _line| @hit_point.distance(point) }.last
          end
          intersections = bounding_lines.zip(bounding_lines.rotate).map { |line1, line2| ::Geom.intersect_line_line(line1, line2) }
          diagonal = intersections[0].vector_to(intersections[2])
          Geom.rectangle intersections[0], diagonal, Sketchup.active_model.edit_transform
        end

        # Returns and save (as focused) the nearest target that has come into focus and hit point. Takes into account the geometry of the model
        # Returns true if focused was changed to nil, false otherwise
        # @param ray [Array<Geom::Point3d, Geom::Vector3d>, Array<Geom::Point3d, Geom::Point3d>] test ray
        # @param input_point [Sketchup::InputPoint] pass input point to take into account model geometry
        # @return [NeedingBoxTool::Target, Boolean]
        def pick(ray, input_point = nil)
          picked = available_targets.each_with_object([]) do |target, cache|
            hit_point = target.hit?(ray)
            next unless hit_point

            cache << [target, hit_point]
          end
          if picked.empty?
            return unless @focused

            @focused = @hit_point = nil
            return true
          else
            picked << [input_point.instance_path.first, input_point.position] if input_point&.instance_path&.any?
            eye = ray.first
            @focused, @hit_point = picked.min_by { |_target, hit_point| eye.distance(hit_point) }
            @focused
          end
        end
      end

      class Target
        extend Forwardable
        include Enumerable

        attr_accessor :side, :panel, :panel_params
        def_delegators :@target, :plane, :vertices, :each

        def initialize(side, offset)
          @side = side
          @target = side.offset offset
        end

        def available?
          panel.nil? || (panel.deleted? if panel.respond_to? :deleted?)
        end

        def hit?(ray)
          return unless available?

          intersection = plane.intersect ray
          return unless intersection

          ray_direction = ray.last.is_a?(::Geom::Vector3d) ? ray.last : ray.first.vector_to(ray.last)
          eye = ray.first
          return intersection if eye.vector_to(intersection).samedirection?(ray_direction) &&
            @target.point_in?(intersection)
        end

        def inspect
          "#{super.match(/^[^\s]+/)[0]}>"
        end
      end

      class PanelCreationParams
        attr_accessor *DEFAULT_PANEL_PARAMS.keys

        def initialize(**params)
          params = DEFAULT_PANEL_PARAMS.merge params
          DEFAULT_PANEL_PARAMS.keys.each { |key| instance_variable_set "@#{key}", params.fetch(key) }
        end

        def toggle_direction
          self.outside_direction = !outside_direction
          true
        end

        def toggle_external_bounds
          self.external_bounds = !external_bounds
          true
        end
      end

      class DefaultParamAccessor

        attr_reader :prompt

        def initialize(param_name, prompt)
          @param_name = param_name
          @prompt = prompt
        end

        def get(params)
          params.public_send @param_name
        end

        def set(params, value)
          return if get(params) == value

          params.public_send "#{@param_name}=", value
        end
      end

      class LengthAccessor < DefaultParamAccessor
        def set(params, value)
          super params, value.to_l
        rescue ArgumentError
          raise ArgumentError, "Invalid length value '#{value}'"
        end
      end

      class CarouselParamsAccessor

        def initialize(*accessors, &params_query)
          @query = params_query
          add *accessors
        end

        def add(*accessors)
          self.accessors.concat accessors
        end

        def get
          active_accessor&.get(params)
        end

        def set(value)
          active_accessor&.set(params(true), value)
        end

        def prompt
          active_accessor&.prompt
        end

        def next
          accessors.rotate!
        end

        private

        def accessors
          @accessors ||= []
        end

        def active_accessor
          @accessors.first
        end

        def params(private = false)
          @query.call(private)
        end
      end
    end
  end
end
