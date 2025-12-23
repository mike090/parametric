require 'testup/testcase'
require_relative '../../src/parametric/lib/geom'

module Parametric
  module Geom
    class TC_Geom < TestUp::TestCase
      def test_rectangle_with_one_invalid_vector
        assert_raises ArgumentError do
          Geom.rectangle ORIGIN, ::Geom::Vector3d.new(20,0,0)
        end
      end

      def test_rectangle_with_one_valid_vector
        subject = Geom.rectangle ORIGIN, ::Geom::Vector3d.new(0,20,30)
        assert_instance_of Rectangle, subject
        expected_vertices_pos = [[0,0,0], [0,20,0], [0,20,30], [0,0,30]]
        assert_equal expected_vertices_pos, subject.map(&:to_a)
      end

      def test_decompose_3d_vector
        subject = Geom.decompose_vector(::Geom::Vector3d.new 10, 20, 30)
        assert_equal [::Geom::Vector3d] * 3, subject.map(&:class)
        expected_vectors_vals = [[10,0,0], [0,20,0], [0,0,30]]
        assert_equal expected_vectors_vals, subject.map(&:to_a)
      end

      def test_decompose_2d_vector
        subject = Geom.decompose_vector(::Geom::Vector3d.new 10, 0, 30)
        assert_equal [::Geom::Vector3d] * 2, subject.map(&:class)
        expected_vectors_vals = [[10,0,0], [0,0,30]]
        assert_equal expected_vectors_vals, subject.map(&:to_a)
      end
    end   
  end
end
