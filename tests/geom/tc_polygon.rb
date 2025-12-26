require_relative '../test_helper'
require 'parametric/geom/polygon'

module Parametric
  module Geom
    class Polygon
      module Tests
        extend Spec::TestsRoot

        describe Polygon do
          let(:vertices) do
            n = 5
            trn = ::Geom::Transformation.rotation(ORIGIN, Z_AXIS, 360.degrees / n)
            vertices = [::Geom::Point3d.new(10,0,3)]
            (n - 1).times { vertices << vertices.last.transform(trn) }
            vertices
          end

          subject { Polygon.new *vertices }

          test_case_name 'TC_Polygon'

          test 'initialization with points' do
            refute_nil subject
          end

          test '#vertices' do
            expect(subject.vertices).must_be_instance_of Array
            assert subject.vertices.all?(::Geom::Point3d)
            expect(subject.vertices.count).must_equal 5
          end

          test '#edges' do
            expect(subject.edges).must_be_instance_of Array
            expect(subject.edges.count).must_equal 5
            assert subject.edges.all?(Array)
            assert (subject.edges.map &:class).all? { |item| item === [::Geom::Point3d]*2 }
            vectors = subject.edges.map { |p0, p1| p1 - p0 }
            expect(vectors.reduce(&:+).length).must_equal 0
          end

          test '#plane' do
            expect(subject.plane).must_be_instance_of Plane
            expect(subject.plane).must_equal [0,0,1,-3]
          end

          test '#center' do
            expect(subject.center).must_equal ORIGIN.offset([0,0,3])
          end

          test '#reverse' do
            new_polygon = subject.reverse
            assert_instance_of Polygon, new_polygon
            refute_same subject, new_polygon
            assert_equal subject.vertices.first, new_polygon.vertices.first
            assert_equal subject.vertices.reverse.rotate(-1), new_polygon.vertices
          end

          test '#reverse!' do
            assert_equal [0,0,1,-3], subject.plane
            assert_same subject, subject.reverse!
            assert_equal [0,0,-1,3], subject.plane
            assert_equal ::Geom::Point3d.new(10,0,3), subject.vertices.first
          end

          test '#point_in' do
            point = ::Geom::Point3d.new(1,1,3)
            assert point.on_plane?(subject.plane)
            assert subject.point_in?(point)
            point = ::Geom::Point3d.new(1,1,2)
            refute point.on_plane?(subject.plane)
            refute subject.point_in?(point) # do'nt raises if point ar'nt on plane
            point = ::Geom::Point3d.new(12,0,3)
            assert point.on_plane?(subject.plane)
            refute subject.point_in?(point)
          end

          test '#offset' do
            new_polygon = subject.offset 1
            assert_instance_of Polygon, new_polygon
            refute_same subject, new_polygon
            assert_equal 5, new_polygon.vertices.count
            vectors = new_polygon.vertices.zip(subject.vertices).map { |p0,p1| p1 - p0 }
            assert vectors.all? { |vector| vector.length == vectors.first.length }
          end
        end
      end
    end
  end
end
