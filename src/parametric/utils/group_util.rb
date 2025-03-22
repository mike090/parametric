module Parametric
	module GroupUtil
		class << self
			def solid?(group)
				group.entities.grep(Sketchup::Face).count > 3 && 
					group.entities.grep(Sketchup::Edge).all? { |edge| edge.faces.count == 2 }
			end

			def group_parallel_faces(group)
				result = []
				faces = group.entities.grep(Sketchup::Face)
				until faces.empty?
					vector = faces.first.normal
					parallel_faces = faces.select { |face| face.normal.parallel? vector }
					result << parallel_faces
					faces -= parallel_faces
				end
				result
			end

			def faces_with_perpendicular_cut(group)
				edges = group.entities.grep Sketchup::Edge
	      group_parallel_faces(group).select do |faces|
		      (edges - faces.flat_map(&:edges)).all? { |edge| edge.line[1].parallel? faces.first.normal }
	      end
	    end

			def panel?(group)
				return false unless solid? group
				
				faces_with_perpendicular_cut(group).any? do |parallel_faces_group|
					parallel_faces_group.count == 2
				end
			end

			def drilling?(group)
				group.get_attribute('Parametric', 'type') == 'drilling'
			end
		end
	end
end