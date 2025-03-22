require_relative '../utils/group_util'

module Parametric
	class DrillingTool
		class << self
			def activate
				@picked = nil
				@panel_face = nil
				update_status
			end

			def onLButtonUp(flags, x, y, view)
				puts 'onLButtonUp'
				puts "#{x}, #{y}"
				# ph = view.pick_helper
				# ph.do_pick(x, y)
				# set_picked(nil) unless @picked&.geometry == ph.element_at(-2)
			end

			def onLButtonDoubleClick(flags, x, y, view)
				puts 'onLButtonDoubleClick'
				# ip = Sketchup::InputPoint.new
				# if ip.pick(view, x, y)
				# 	picked = classify_picked(ip.instance_path)
				# 	set_picked(picked)
				# 	if @picked.instance_of? Parametric::Panel
				# 		@panel_face = ip.face
				# 	end
				# end
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
					Parametric::Panel.new picked
				elsif Parametric::GroupUtil.drilling?(picked)
					Parametric::DrillingGroup.new inst_path.to_a[-3]
				end
			end

			def draw
				
			end
		end
	end

	class Sys32Mapper
		attr_reader :offset

		def initialize(panel, face)
			@panel = panel
			set_face face
			@offset = 37.mm
		end

		def activate
			
		end

		def onMouseMove(flags, x, y, view)
			ph = view.pick_helper
			if ph.do_pick(x,y) > 0
				view.invalidate if set_face(ph.picked_face)
			end
		end

		def draw(view)
			anchors.each do |edge, anchors|
				anchors.each do |anchor|
					mplxr = edge.reversed_in?(@face) ? -1 : 1
					vector = edge.line.last.transform(
						Transformation.rotation anchor,
						@face.normal,
						mplxr * 90.degrees
					).tap { |vector| vector.length = 25.mm }
					view.draw_line anchor, anchor.offset(vector)
				end
			end
		end

		private

		def set_face(face)
			return if @face == face

			@face = @panel.faces.include?(face) ? face : nil
			@anchors = nil
			update_status
			true
		end

		def update_status
			message = if @face 
				'Click on anchor to add drilling'
			else
				'Select panel face'
			end
			Sketchup.set_status_text message
		end

		def anchors
			return {} unless @face
			
			@anchors ||= @face.edges.group_by(&:length).max.last.to_h do |edge|
				v_offset = Geom::Vector3d.new(edge.line.last).tap { |vector| vector.length = @offset }
				anchor_1 = edge.start.position.offset v_offset
				anchor_2 = edge.end.position.offset v_offset.reverse
				[edge, [anchor_1, anchor_2]]
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
			Parametric::GroupUtil.faces_with_perpendicular_cut(@geometry).max do |a, b|
				a[0].area <=> b[0].area
			end
		end

		def edges
			@geometry.entities.grep(Sketchup::Face) - faces
		end
	end

	class DrillingGroup
		attr_reader :geometry

		def initialize(geometry)
			@geometry = geometry
		end
	end
end