require_relative '../../test_helper'
require 'parametric/lib/geom/box'

module Parametric
  module Geom
    class Box
      module Tests
        extend Spec::TestsRoot

        describe Box do
          subject { Box.new *params }

          let(:params) { @box_params || default_params }
          let(:default_params) do
            [::Geom::Point3d.new(10,10),
              ::Geom::Vector3d.new(20,0,0),
              ::Geom::Vector3d.new(0,30,0),
              ::Geom::Vector3d.new(0,0,40)
            ]
          end

          attr_reader :box_params

          test 'initialization with vertex and three vectors' do
            expect(subject).must_be_instance_of Box
          end

          test 'initialization with vertex and one vector' do
            @box_params = [ORIGIN, ::Geom::Vector3d.new(40,30,20)]
            expect(subject).must_be_instance_of Box
          end

          test '#vertices' do
            vertices = subject.vertices
            assert_instance_of Array, vertices
            assert_equal [::Geom::Point3d]*8, vertices.map(&:class)
          end

          test '#edges' do
            edges = subject.edges
            expect(edges).must_be_instance_of Array
            assert_equal [[::Geom::Point3d]*2]*12, edges.map { |edge| edge.map(&:class) }
          end

          test '#sides' do
            expect(subject.sides).must_be_instance_of Array
            assert_equal [Rectangle]*6, subject.sides.map(&:class)
            assert_equal 8, subject.sides.map(&:vertices).flatten.uniq { |point| point.to_a }.count
          end

          test '#bounds' do
            bb = subject.bounds
            test_bb = ::Geom::BoundingBox.new
            test_bb.add default_params.first, default_params.reduce(&:+)
            assert_equal [test_bb.min, test_bb.max], [bb.min, bb.max]
          end

          test '#connected' do
            connected = subject.connected ::Geom::Point3d.new(10,10)
            expected_vertices = [[30,10],[10,40],[10,10,40]].map { |pos| ::Geom::Point3d.new pos }
            assert_equal expected_vertices, connected
            connected = subject.connected ::Geom::Point3d.new(30,40,40)
            expected_vertices = [[30,40],[30,10,40],[10,40,40]].map { |pos| ::Geom::Point3d.new pos }
            assert_equal expected_vertices, connected
          end

          test '#center' do
            assert_equal ::Geom::Point3d.new(20,25,20), subject.center
          end

          test 'sides_normals_direction' do
            out_durection = proc { |center, side| center.vector_to(center.project_to_plane side.plane).normalize }
            center = subject.center

            subject = Box.new *default_params
            assert subject.sides.all? { |side| side.plane.normal.samedirection? out_durection.call(center, side) }

            default_params[2], default_params[1] = default_params[1,2]
            subject = Box.new *default_params
            assert subject.sides.all? { |side| side.plane.normal.samedirection? out_durection.(center, side) }
          end
        end
      end
    end
  end
end
