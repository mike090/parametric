require_relative '../test_helper'
require 'parametric/geom/flatten'

module Parametric
  module Geom
    class Flatten
      module Tests
        extend Spec::TestsRoot

        describe Flatten do

          subject { Flatten.new *params }

          describe 'initialization' do
            attr_reader :params

            test_case_name 'TC_initialization'

            let(:points) { [[1,1], [1,3], [3,3], [3,1]].map { |pos| ::Geom::Point3d.new pos } }

            test 'initialization with array of points' do
              @params = [points, Z_AXIS]
              assert_instance_of Flatten, subject
            end

            test 'initialization with polygon' do
              @params = [Polygon.new(points), Z_AXIS.reverse]
              assert_instance_of Flatten, subject
            end

            it 'raises with invalid vector' do
              @params = [points, X_AXIS]
              assert_raises(TypeError) { subject }
            end
          end

          let(:n) { 6 }
          let(:profile) do
            trn = ::Geom::Transformation.rotation ORIGIN, Z_AXIS, 360.degrees/n
            (n-1).times.reduce([::Geom::Point3d.new(100.mm,0,1)]) do |vertices|
              vertices << vertices.last.transform(trn)
            end
          end
          let(:params) { [profile, ::Geom::Vector3d.new(0,0,30.mm)] }

          test_case_name 'TC_Flatten'

          test '#vertices' do
            assert_instance_of Array, subject.vertices
            assert_equal n*2, subject.vertices.count
            assert subject.vertices.all?(::Geom::Point3d)
            assert profile.all? do |point|
              subject.vertices.include? point
              subject.vertices.include? point.offset(params.last)
            end
          end

          test '#edges' do
            assert_instance_of Array, subject.edges
            assert_equal [[::Geom::Point3d]*2]*3*n,
              subject.edges.map { |edge| edge.map(&:class) }
          end

          test '#sides' do
            assert_instance_of Array, subject.sides
            assert_equal [Polygon]*(n+2), subject.sides.map(&:class)
            center = subject.bounds.center
            assert subject.sides.all? do |side| # test sides normals outside direction
              center.vector_to(center.project_to_plane side.plane).samedirection? side.plane.normal
            end
          end
        end
      end
    end
  end
end
