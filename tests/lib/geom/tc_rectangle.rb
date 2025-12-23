require_relative '../../test_helper'
require 'parametric/lib/geom/rectangle'

module Parametric
  module Geom
    class Rectangle
      module Tests
        extend Spec::TestsRoot

        describe Rectangle do
          test_case_name 'TC_Rectangle'

          subject do
            params = rectangle_params || default_params
            Rectangle.new(*params)
          end
          let(:default_params) do
            [
              ::Geom::Point3d.new(100, 100, 100),
              [[450,0,0],[0,570,0]].map { |val| ::Geom::Vector3d.new val }
            ].flatten
          end
          attr_reader :rectangle_params

          test 'initialization with valid params' do
            @rectangle_params = [::Geom::Point3d.new(1,1), X_AXIS, Z_AXIS]
            assert_instance_of Rectangle, subject
          end

          test 'initialization with not perpendicular vectors' do
            @rectangle_params = [ORIGIN, X_AXIS, ::Geom::Vector3d.new(0.99, 1, 0)]
            assert_raises(TypeError, "vectors aren't perpendicular") { subject }
          end

          test '#vertices' do
            assert_instance_of Array, subject.vertices
            assert_equal [::Geom::Point3d]*4, subject.vertices.map(&:class)
            exp_vertices = [
              [100,100,100], [550,100,100],
              [550,670,100], [100,670,100]
            ].map { |pos| ::Geom::Point3d.new pos }
            assert_equal exp_vertices, subject.vertices
          end

          test '#edges' do
            assert_instance_of Array, subject.edges
            assert_equal [[::Geom::Point3d]*2]*4, subject.edges.map { |edge| edge.map(&:class) }
          end

          test '#plane' do
            assert_instance_of Plane, subject.plane
            assert_equal [0,0,1,-100], subject.plane 
          end

          test '#center' do
            assert_instance_of ::Geom::Point3d, subject.center
            assert_equal ::Geom::Point3d.new((100+450/2),(100+570/2),100), subject.center
          end

          test '#offset' do
            offseted = subject.offset(16)
            assert_instance_of Rectangle, offseted
            refute_same subject, offseted
            assert_equal ::Geom::Point3d.new(116,116,100), offseted.vertices[0]
            assert_equal ::Geom::Point3d.new((550-16),(670-16),100), offseted.vertices[2]
          end

          test '#offset!' do
            offseted = subject.offset!(16)
            assert_same subject, offseted
            assert_equal ::Geom::Point3d.new(116,116,100), offseted.vertices[0]
            assert_equal ::Geom::Point3d.new((550-16),(670-16),100), offseted.vertices[2]
          end

          test '#offset with relative value' do
            offseted = subject.offset('1/5')
            assert_instance_of Rectangle, offseted
            assert_equal ::Geom::Point3d.new(190,214,100), offseted.vertices[0]
            assert_equal ::Geom::Point3d.new((550-90),(670-114),100), offseted.vertices[2]
          end

          test '#shift' do
            shifted = subject.shift -50
            assert_instance_of Rectangle, shifted
            refute_same subject, shifted
            expected_vertices = [[100,100,50],
              [550,670,50]].map { |pos| ::Geom::Point3d.new pos }
            assert_equal expected_vertices, shifted.vertices.slice((0..).step 2)
            
            shifted = subject.shift 50
            expected_vertices = [[100,100,150],
              [550,670,150]].map { |pos| ::Geom::Point3d.new pos }
            assert_equal expected_vertices, shifted.vertices.slice((0..).step 2)
          end

          test '#shift!' do
            shifted = subject.shift! 50
            assert_same subject, shifted
            assert_equal ::Geom::Point3d.new(100,100,150), shifted.vertex
            assert_equal default_params[1..], shifted.vectors
            assert_nil shifted.instance_variable_get(:@polygon)
            puts shifted.inspect
            expected_vertices = [[100,100,150],
              [550,670,150]].map { |pos| ::Geom::Point3d.new pos }
            assert_equal expected_vertices, shifted.vertices.slice((0..).step 2)
          end

          test '#reverse' do
            reversed = subject.reverse
            assert_instance_of Rectangle, reversed
            refute_same subject, reversed
            assert_equal subject.vertices.rotate.reverse, reversed.vertices
            assert_equal ::Geom::Vector3d.new, (subject.plane.normal + reversed.plane.normal)
          end

          test '#reverse!' do
            assert_equal [0,0,1,-100], subject.plane
            reversed = subject.reverse!
            assert_same subject, reversed
            assert_equal [0,0,-1,100], subject.plane
            assert_equal ::Geom::Point3d.new(100,670,100), reversed.vertices[1]
          end

          test 'comparsion methods' do
            rectangle = Geom::rectangle ::Geom::Point3d.new(100,100,100), ::Geom::Vector3d.new(450,570,0)
            refute_same rectangle, subject
            assert_equal rectangle, subject
          end

          it 'can be enumerated' do
            expect(subject).must_be_kind_of Enumerable
            expect(subject).must_respond_to :each
            expect(subject.to_a).must_equal subject.vertices
          end
        end
      end
    end
  end
end
