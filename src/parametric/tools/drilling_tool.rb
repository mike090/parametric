require_relative '../utils/group_util'

module Parametric
	class DrillingTool
		class << self
			def activate
				puts 'DrillingTool activated'
				@picked = nil
				@panel_face = nil
				update_status
			end

			def onLButtonUp(flags, x, y, view)

			end

			def onLButtonDoubleClick(flags, x, y, view)
				ip = Sketchup::InputPoint.new
				if ip.pick(view, x, y)
					picked = classify_picked(ip.instance_path)
					if picked.instance_of? Parametric::Panel
						face = ip.face
						mapper = Parametric::Sys32Mapper.new(
							picked,
							face,
							ip.transformation
						)
						Sketchup.active_model.tools.push_tool mapper
					end
				end
			end

			def set_picked picked
				return if @picked == picked

				@picked = picked
				update_status
			end

			def update_status
				message = @picked ? "Picked: #{@picked}" : 'Select drilling group or double click panel to add drilling'
				Sketchup.set_status_text message
			end

			def classify_picked(inst_path)
				picked = inst_path.to_a[-2]
				return unless picked.instance_of?(Sketchup::Group)

				if Parametric::GroupUtil.panel?(picked)
					Parametric::Panel.new(picked)
				elsif Parametric::GroupUtil.drilling?(picked)
					Parametric::DrillingGroup.new(inst_path.to_a[-3])
				end
			end

			def draw(view)
				
			end
		end
	end

	class Sys32Mapper

		KEY_FLAGS = { VK_SHIFT => CONSTRAIN_MODIFIER_MASK, VK_CONTROL => COPY_MODIFIER_MASK }.freeze

		def initialize(panel, panel_face, panel_transformation)
			@panel = panel
			@offset = 37.mm
			self.panel_face = panel_face
			@transformation = panel_transformation
			@mouse_ip = Sketchup::InputPoint.new
		end

		def activate
			update_status
			Sketchup.active_model.active_view.invalidate
		end

		def onMouseMove(flags, x, y, view)
			ph = view.pick_helper
			ph.do_pick(x,y)
			@mouse_ip.pick view, x, y
			@flags = flags
			self.panel_face = ph.picked_face
			view.invalidate
		end

		def onKeyDown(key, repeat, flags, view)
			return if repeat != 1
			flag = KEY_FLAGS.fetch key, 0	
			return if @flags & flag == flag

			@flags |= flag
			view.invalidate
		end

		def onKeyUp(key, repeat, flags, view)
			return if repeat != 1

			flag = KEY_FLAGS.fetch key, 0	
			return if @flags & flag == 0

			@flags ^= flag
			view.invalidate
		end

		def onLButtonDown(flags, x, y, view)
			@mouse_ip.pick(view, x, y)
			puts @mouse_ip.instance_path.to_a
			# return Sketchup.active_model.tools.pop_tool unless @mouse_ip.instance_path.to_a.include?(@panel.geometry)
			puts "selected: #{selected_anchors.count}"
		end

		def draw(view)
			return unless @panel_face

			selected = selected_anchors
			(anchors - selected).each { |anchor| draw_anchor(view, anchor) }
			selected.each { |anchor| draw_anchor(view, anchor, true) } unless selected.empty?
		end

		def onUserText(text, view)
		  self.offset = text.to_l
		  define_anchors
		  view.invalidate
		rescue ArgumentError
		  view.tooltip = 'Invalid length'
		end

		private

		def selected_anchors
			local_pos = to_panel(@mouse_ip.position)
			focused = anchors.find { |anchor| anchor.position.distance(local_pos) < 50.mm }
			return [] unless focused

			selected = [focused]
			selected.concat same_edge_anchors(focused) if @flags & CONSTRAIN_MODIFIER_MASK == CONSTRAIN_MODIFIER_MASK
			selected.concat opposite_anchors(selected) if @flags & COPY_MODIFIER_MASK == COPY_MODIFIER_MASK
			selected
		end

		def anchors
			@anchors ||= []
		end

		def offset=(value)
			return if @offset == value

			@offset = value
			anchors.each { |anchor| anchor.offset = @offset }
		end

		def draw_anchor(view, anchor, selected = false)
			lines = [-12.5.degrees, 12.5.degrees].map do |angle|
				transformation = Geom::Transformation.rotation(anchor.position, anchor.z_axis, angle)
				vector = anchor.y_axis.transform(transformation)
				vector.length = 20.mm
				[anchor.position, anchor.position.offset(vector)]
			end
			lines << [anchor.position, anchor.position.offset(anchor.y_axis, 35.mm)]
			view.drawing_color = selected ? 'blue' : 'black'
			lines.each { |line| view.draw_line to_model(line) }
		end

		def to_model(object)
			case object
			when Enumerable
				object.map { |item| item.transform @transformation if item.respond_to? :transform }
			else
				object.transform @transformation if object.respond_to? :transform
			end
		end

		def to_panel(object)
			case object
			when Enumerable
				object.map { |item| item.transform @transformation.inverse if item.respond_to? :transform }
			else
				object.transform @transformation.inverse if object.respond_to? :transform
			end				
		end

		def same_edge_anchors(anchor)
			(anchors - [anchor]).select do |achr|
				achr.edge == anchor.edge && achr.offset == anchor.offset
			end
		end

		def opposite_anchors(selected)
			(anchors - selected).select do |anchor|
			 	selected.any? { |sel| anchor.position.on_line? [sel.position, sel.y_axis] } 
			end
		end

		def panel_face=(value)
			return if @panel_face == value

			@panel_face = @panel.faces.include?(value) ? value : nil
			define_anchors
			update_status
		end

		def update_status
			message = if @panel_face 
				'Click on anchor to add drilling'
			else
				'Select panel face'
			end
			Sketchup.set_status_text message
		end

		def define_anchors
			anchors.clear
			return unless @panel_face
			
			@panel_face.edges.sort_by(&:length).last(2).each do |edge|
				anchors << Parametric::EdgeAnchor.new(@panel, edge, edge.start, offset)
				anchors << Parametric::EdgeAnchor.new(@panel, edge, edge.end, offset)
				anchors << Parametric::EdgeAnchor.new(@panel, edge, edge.start, edge.length / 2)
			end
		end
	end

	class Panel
		attr_reader :geometry

		def initialize(geometry)
			valid = geometry.instance_of?(Sketchup::Group) && Parametric::GroupUtil.panel?(geometry)
			raise 'invalid geometry to create panel' unless valid
			@geometry = geometry
		end

		def faces
			@faces ||= Parametric::GroupUtil.faces_with_perpendicular_cut(@geometry).max do |a, b|
				a[0].area <=> b[0].area
			end
		end

		def edges
			@edges ||= @geometry.entities.grep(Sketchup::Face) - faces
		end
	end

	class DrillingGroup
		attr_reader :geometry

		def initialize(geometry)
			@geometry = geometry
		end
	end

	class EdgeAnchor
		attr_reader :edge, :offset

		def initialize(panel, edge, vertice = edge.start, offset = 37.mm)
			@edge = edge
			@panel = panel
			@offset = offset
			@vertice = vertice
		end

		def offset=(value)
			return if @offset == value

			@position = nil
			@line = nil
			@offset = value
		end

		def position
			@position ||= @vertice.position.offset x_axis, @offset
		end

		def transformation
			@transformation ||= Geom::Transformation.new x_axis, y_axis, z_axis, position
		end

		# def line
		# 	@line ||= [position, position.offset(y_axis, 35.mm)]
		# end

		def panel_face
			@panel_face ||= (@edge.faces & @panel.faces).first 
		end

		def panel_edge
			panel_edge ||= (@edge.faces & @panel.edges).first
		end

		def x_axis
			@x_axis ||= (@vertice == edge.start) ? edge.line.last.normalize : edge.line.last.normalize.reverse!
		end

		def y_axis
			multiplexer = edge.reversed_in?(panel_face) ? 1 : -1
			rotation = Geom::Transformation.rotation(
					position,
					@edge.line.last,
					multiplexer * 90.degrees
			)
			@y_axis ||= z_axis.transform(rotation).normalize
		end

		def z_axis
			@z_axis ||= panel_face.normal
		end
	end
end