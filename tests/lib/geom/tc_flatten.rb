require 'testup/testcase'
require 'parametric/lib/geom/flatten'

class TC_Flatten < TestUp::TestCase
	def test_vertices
		pos = [0.0,0.0,0.0], [0.0,1.0,0.0], [1.0,1.0,0.0], [1.0,0.0,0.0]
		subject = Parametric::Geom::Flatten.new(pos, Z_AXIS).vertices
		assert_empty pos - subject.map(&:to_a)
		assert_equal 8, subject.count
	end

	def test_edges
		pos = [0.0,0.0,0.0], [0.0,1.0,0.0], [1.0,1.0,0.0], [1.0,0.0,0.0]
		subject = Parametric::Geom::Flatten.new(pos, Z_AXIS).edges
		assert_equal 12, subject.count
		assert_equal 12, subject.map(&:to_set).uniq.count
		assert subject.all? { |p1, p2| (p2 - p1).length == 1 }
	end

	def test_sides
		pos = [0.0,0.0,0.0], [0.0,0.0,1.0], [0.0,1.0,1.0], [0.0,1.0,0.0]
		subject = Parametric::Geom::Flatten.new(pos, X_AXIS).sides
		assert_equal 6, subject.count
		assert_equal Geom::Vector3d.new(0,0,0), subject.map { |side| side.plane.normal }.reduce(&:*)
	end
end