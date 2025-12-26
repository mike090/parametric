require_relative '../test_helper'
require 'parametric/geom/plane'

module Parametric
  module Geom
    class Plane
      module Tests
        extend Spec::TestsRoot

        describe Plane do
          attr_accessor :params

          describe 'initialization' do

            test_case_name 'TC_initialization'

            subject { Plane.new params }

            test 'initialization with a point and a vector' do
              self.params = [ORIGIN, Z_AXIS]
              expect(subject).must_equal [0,0,1,0]
            end

            test 'initialization with a raw data' do
              self.params = [1,0,0,1]
              expect(subject).must_equal [1,0,0,1]
            end

            test 'initialization with a point and a ray' do
              point = ::Geom::Point3d.new(1,1,1)
              ray = [::Geom::Point3d.new(0,0,1), X_AXIS]
              self.params = [point, ray]
              expect(subject).must_equal [0,0,1,-1]
            end

            test 'initialization with points' do
              self.params = [[0,0,1], [0,1,1], [1,1,1], [1,0,1]].map { |pos| ::Geom::Point3d.new pos }
              expect(subject).must_equal [0,0,-1,1]
            end

            test 'initialization with point and edge' do
              edge = [[0,1], [1,1]].map { |pos| ::Geom::Point3d.new pos }
              self.params = [ORIGIN, edge]
              expect(subject).must_equal [0,0,-1,0]
            end

            test 'unplanar points raises' do
              self.params = [[0,0,1], [0,1,1], [1,1,1], [1,0,2]].map { |pos| ::Geom::Point3d.new pos }
              assert_raises(TypeError, 'Points are not planar') {subject} 
            end
          end

          describe '#normal' do
            test_case_name 'TC_normal'

            subject { plane.normal }
            let(:plane) { Plane.new params }
            it 'returns unittvector' do
              self.params = [::Geom::Point3d.new(1,1,1), ::Geom::Vector3d.new(1,1,1)]
              expect(subject).must_be :unitvector?
            end
          end

          describe '#reverse' do
            test_case_name 'TC_reverse'

            let(:plane) { Plane.new [ORIGIN, ::Geom::Vector3d.new(1,1,1)] }
            subject { plane.reverse }

            it 'returns new plane object' do
              expect(subject).must_be_instance_of Plane
              expect(subject).wont_be_same_as plane
            end

            it 'reverses normal' do
              expect(subject.normal).must_equal plane.normal.reverse
            end
          end

          describe '#parallel?' do

            let(:plane) { Plane.new [1,0,0,-1] }

            context 'when normals are samedirection' do
              test_case_name 'TC_parallel_samedirection'

              subject { Plane.new [1,0,0,3] }

              it 'parallel if normals are samedirection' do
                expect(subject.normal).must_be :samedirection?, plane.normal
                expect(subject).must_be :parallel?, plane
              end
            end

            context 'when normals are contradirection' do
              test_case_name 'TC_parallel_contradirection'

              subject { Plane.new [-1,0,0,5] }

              it 'parallel if normals are contradirection' do
                expect(subject.normal).wont_be :samedirection?, plane.normal
                expect(subject.normal).must_be :parallel?, plane.normal
                expect(subject).must_be :parallel?, plane
              end
            end
          end

          describe '#internal_position' do
            test_case_name 'TC_internal_position'

            let(:plane) { Plane.new [::Geom::Point3d.new(1,2,3), ::Geom::Vector3d.new(4,5,6)] }
            let(:point) { ::Geom::Point3d.new(7,8,9).project_to_plane plane }
            subject { plane.internal_position point }

            it 'returns 2d position' do
              expect(subject.z).must_equal 0
              p0 = ORIGIN.project_to_plane(plane)
              expect(plane.internal_position p0).must_equal ORIGIN
            end

            test 'internal_positions' do
              points = [[0,0], [5,0], [10,0]].map { |pos| ::Geom::Point3d.new(pos).project_to_plane plane }
              vectors = points.zip(points.rotate) { |p1, p2| p1.vector_to p2 }
              _points = points.map { |point| plane.internal_position point }
              _vectors = _points.zip(_points.rotate) { |p1, p2| p1.vector_to p2 }
              assert_equal vectors, _vectors
              assert_equal [0,0,0], _points.map(&:z)
            end

            it 'raises TypeError when point does not belong to plane' do
              point = ::Geom::Point3d.new 7,8,9
              assert_raises(TypeError) { plane.internal_position point }
            end
          end

          describe '#==' do
            test_case_name 'TC_equality'

            test '==' do
              plane1 = Plane.new [1,0,0,0]
              plane2 = Plane.new [-1,0,0,0]
              plane3 = Plane.new [1,0,0,0]
              refute_same plane1, plane2
              refute_same plane2, plane3
              refute_same plane1, plane3
              assert_equal plane1, plane3
              refute_equal plane1, plane2
              refute_equal plane2, plane3
            end
          end

          describe '#intersect' do
            test_case_name 'TC_intersect'

            let(:plane) { Plane.new [0,1,0,6] }
            subject { plane.intersect object }
            attr_accessor :object

            test 'intersect with plane' do
              self.object = Plane.new [1,0,0,3]
              expect(subject).must_be_instance_of Array
              expect(subject.map &:class).must_equal [::Geom::Point3d, ::Geom::Vector3d]
              expect(subject.first).must_be :on_plane?, object
              expect(subject.first).must_be :on_plane?, plane
              expect(subject.reduce(&:+)).must_be :on_plane?, object
              expect(subject.reduce(&:+)).must_be :on_plane?, plane
            end

            test 'intersect with line' do
              self.object = [::Geom::Point3d.new(0,1,4), Y_AXIS]
              expect(subject).must_be_instance_of ::Geom::Point3d
              expect(subject).must_equal ::Geom::Point3d.new(0,-6,4)
            end

            it 'raises TypeError when initialization are impossible' do
              self.object = Object.new
              assert_raises(TypeError) { subject }
              self.object = [X_AXIS, ORIGIN]
              assert_raises(TypeError) { subject }
            end
          end
        end
      end
    end
  end
end
