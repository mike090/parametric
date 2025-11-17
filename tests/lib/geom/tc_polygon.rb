require 'testup/testcase'
require 'parametric/lib/geom/polygon'

class TC_Polygon < TestUp::TestCase
	def test_plane
		points = [ORIGIN, [1,0,0], [0,1,0]]
		assert_equal Z_AXIS.to_a << 0, Parametric::Geom::Polygon.new(points).plane
		assert_equal Z_AXIS.reverse.to_a << 0, Parametric::Geom::Polygon.new(points.reverse).plane
	end

	def test_vrtices
		subject = Parametric::Geom::Polygon.new ORIGIN, [1,0,0], [0,1,0]
		assert_equal [ORIGIN, [1,0,0], [0,1,0]], subject.vertices.map(&:to_a)
	end

	def test_edges
		subject = Parametric::Geom::Polygon.new [0,0,0], [1,0,0], [0,1,0]
		assert_equal(
			[
				[ Geom::Point3d.new(0,0,0), Geom::Point3d.new(1,0,0) ],
				[ Geom::Point3d.new(1,0,0), Geom::Point3d.new(0,1,0) ],
				[ Geom::Point3d.new(0,1,0), Geom::Point3d.new(0,0,0) ]
			],  subject.edges
		)
	end

	def test_reverse!
		positions = [ [0,0,0], [1,0,0], [1,1,0], [0,1,0] ]
		subject = Parametric::Geom::Polygon.new positions
		subject.reverse!
		assert_equal [0,0,-1,0], subject.plane
		assert_equal [ [0,0,0],[0,1,0],[1,1,0],[1,0,0] ], subject.vertices.map(&:to_a)
	end

	def test_shift
		pos = [ [-1,-1,0],[1,-1,0],[1,1,0],[-1,1,0] ]
		source = Parametric::Geom::Polygon.new pos
		subject = source.shift(Z_AXIS,1)
		assert_instance_of Parametric::Geom::Polygon, subject
		assert_equal [ [-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1] ], subject.map(&:to_a)
		assert_equal [ [-1,-1,0],[1,-1,0],[1,1,0],[-1,1,0] ], source.map(&:to_a)
	end

	def test_offset
		source = Parametric::Geom::Polygon.new [ [0,0,0], [5,0,0], [5,5,0], [0,5,0] ]
		subject = source.offset(-1)
		assert_instance_of Parametric::Geom::Polygon, subject
		assert_equal [ [1,1,0], [4,1,0], [4,4,0], [1,4,0] ], subject.map(&:to_a)
	end
end