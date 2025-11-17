require 'testup/testcase'
require 'parametric/lib/geom/plane'

class TC_Plane < TestUp::TestCase
	def test_from_points
		subject = Parametric::Geom::Plane.new([0,0,0],[1,0,0],[0,1,0])
		assert_equal [0,0,1,0], subject
	end

	def test_normal_direction
		vrtices = [ORIGIN,[0,1,0],[1,0,0]]
		assert_equal Parametric::Geom::Plane.new(*vrtices).normal, Z_AXIS.reverse
		assert_equal Parametric::Geom::Plane.new(vrtices.reverse).normal, Z_AXIS
	end

	def test_from_point_and_vector
		subject = Parametric::Geom::Plane.new(Geom::Point3d.new(1,1,1), Z_AXIS)
		assert_equal Z_AXIS.to_a << -1, subject
	end

	def test_normal
		subject = Parametric::Geom::Plane.new(Geom::Point3d.new(1,2,3),Geom::Vector3d.new(0,0,-2))
		assert_equal Z_AXIS.reverse, subject.normal
		assert_equal 3, subject.last
	end

	def test_reverse
		subject = Parametric::Geom::Plane.new [0,0,1,2]
		assert_equal [0,0,-1,-2], subject.reverse
	end

end