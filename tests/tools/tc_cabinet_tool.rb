require_relative '../test_helper'
require_relative '../../src/parametric/tools'

# model = Sketchup.active_model
# view = model.active_view
# box_params = [
#   Geom::Point3d.new(300.mm, 100.mm, 150.mm),
#   Parametric::Geom.decompose_vector(Geom::Vector3d.new 450.mm,570.mm,720.mm)
# ].flatten
# tool = Parametric::Tools::CabinetTool::BuilderStage.new box_params
# model.select_tool tool

module Parametric
  module Tools
    class CabinetTool
      class Model
        module Tests
          extend Spec::TestsRoot

          describe Model do
            let(:box_params) { [::Geom::Point3d.new(1,1,1), Geom.decompose_vector(::Geom::Vector3d.new(3,4,5))].flatten }
            subject { Model.new *box_params }

            it 'can define its own bounds' do
              expect(subject.bounds).must_be_instance_of ::Geom::BoundingBox
              expect(subject.bounds.corner 0).must_equal ::Geom::Point3d.new(1,1,1)
              expect(subject.bounds.corner 7).must_equal ::Geom::Point3d.new(4,5,6)
            end

            it 'has 12 edges' do
              expect(subject.edges.map { |edge| edge.map(&:class) }).must_equal [[::Geom::Point3d,::Geom::Point3d]] * 12
            end

            it 'has 6 related to the side targets' do
              expect(subject.targets.map(&:class)).must_equal [Target] * 6
              assert subject.targets.all? { |tg| tg.vertices.all? { |pt| tg.side.point_in? pt } } 
            end

            it 'track available targets' do
              expect(subject.available_targets.map &:class).must_equal [Target] * 6
              subject.targets[1,2].each { |target| target.panel = 'fake_panel' }
              expect(subject.available_targets).must_be :count, 4
            end

            it 'not focused by default' do
              assert_nil subject.focused
            end

            describe 'pickray interaction' do
              before { subject.pick pickray }


              context 'case pickray hit some target' do
                let(:pickray) { [subject.bounds.center.offset(Y_AXIS.reverse, 100), Y_AXIS] }
                
                it 'returns focused' do
                  assert_instance_of Target, subject.focused
                end

                it 'can return profile bounds' do
                  assert_instance_of Geom::Rectangle, subject.profile_bounds
                end  
              end

              context 'case pickray missed' do
                let(:pickray) { [ORIGIN, Y_AXIS] }

                it 'focused are nil' do
                  assert_nil subject.focused
                end

                it 'profile bounds are nil' do
                  assert_nil subject.profile_bounds
                end
              end
            end
          end
        end        
      end

      class Target
        module Tests
          extend Spec::TestsRoot

          describe Target do
            test_case_name 'TC_Target'

            let(:side) { Geom::Rectangle.new ::Geom::Point3d.new(1,1,1), *Geom.decompose_vector(::Geom::Vector3d.new 0,4,8) }
            subject { Target.new side, '1/4' }
            let(:expected_vertices) { Geom::Rectangle.new(::Geom::Point3d.new(1,2,3), *Geom.decompose_vector(::Geom::Vector3d.new 0,2,4)).vertices }
            
            it('save side') { assert_equal side, subject.side }
            it('has expected position') { assert_equal expected_vertices, subject.vertices }
            it('available unless panel created') do
              assert subject.available?
              subject.panel = 'panel'
              refute subject.available?
            end
            it 'can evaluate a hit' do
              assert subject.hit? [::Geom::Point3d.new(0,2.5,3.5), X_AXIS]
              refute subject.hit? [::Geom::Point3d.new(0,1,2), X_AXIS]
            end

            it 'can be enumerated' do
              expect(subject).must_be_kind_of Enumerable
              expect(subject).must_respond_to :each
              expect(subject.to_a).must_equal subject.vertices
            end
          end
        end
      end

      class LengthAccessor
        module Tests
          extend Spec::TestsRoot

          describe LengthAccessor do
            let(:default_params) { PanelCreationParams.new }
            subject { LengthAccessor.new :thickness, '' }

            it('can read params') { assert_equal default_params.thickness, subject.get(default_params) }
            it 'can write params' do
              subject.set(default_params, '18 mm')
              assert_equal 18.mm, default_params.thickness
            end
          end
        end
      end

      class CarouselParamsAccessor
        module Tests
          extend Spec::TestsRoot

          describe CarouselParamsAccessor do
            let(:params) { PanelCreationParams.new }
            let(:params_query) { proc { |private| params } }
            let(:accessors) do
              %i(thickness offset shift).map { |key| LengthAccessor.new key, key.to_s }
            end
            subject { CarouselParamsAccessor.new *accessors, &params_query }

            it 'can spin accessors' do
              %w(thickness offset shift).each { |prompt| assert_equal prompt, subject.prompt; subject.next }
            end
            it 'can read params' do
              %i(thickness offset shift).each { |key| assert_equal params.public_send(key), subject.get; subject.next }
            end
            it 'can set params' do
              new_params = { thickness: 18.mm, offset: -2.mm }
              new_params.values.each { |val| subject.set(val); subject.next }
              new_params.each { |k,v| assert_equal v, params.public_send(k) }
            end
          end
        end
      end

      class BuilderStage
      # SU hides exceptions that occur during the tool workflow
      # To make sure they aren't raises at least in typical cases

        module Tests
          extend Spec::TestsRoot

          describe BuilderStage do
            describe '#draw' do
              subject { BuilderStage.new box_params }
              let(:box_params) do
                [
                  ::Geom::Point3d.new(100.mm,100.mm,150.mm),
                  Geom.decompose_vector(::Geom::Vector3d.new 450.mm,570.mm,720.mm)
                ].flatten
              end
              let(:box) { Geom::Box.new(*box_params) }
              let(:view) { Sketchup.active_model.active_view }
              let(:mock_view) { Minitest::Mock.new }

              before { subject.activate }

              define_method :expect_to_draw_module_bounds do |mock|
                mock.expect :drawing_color=, nil, [Sketchup::Color]
                mock.expect :line_width=, nil, [Integer]
                mock.expect :draw, nil, [GL_LINES, Array]
              end

              define_method :expect_to_draw_targets do |mock, targets_count = 6|
                mock.expect :drawing_color=, nil, [Sketchup::Color]
                targets_count.times { mock.expect :draw, nil, [GL_POLYGON] + [::Geom::Point3d]*4 }
              end

              define_method :expect_to_draw_panel_preview do |mock|
                2.times { mock.expect :drawing_color=, nil, [Sketchup::Color] }
                mock.expect :draw, nil, [GL_LINES, Array]
                6.times { mock.expect :draw, nil, [GL_POLYGON] + [::Geom::Point3d]*4 }
              end

              test_case_name 'TC_draw'

              test 'no targets has been chosen' do
                expect_to_draw_module_bounds(mock_view)
                expect_to_draw_targets(mock_view)

                subject.draw mock_view
                assert mock_view.verify
              end

              test 'targets has been chosen' do
                x,y = view.screen_coords(box.sides.first.center).to_a
                subject.onMouseMove(nil, x, y, view)
                refute_nil subject.instance_variable_get(:@model).focused
                expect_to_draw_module_bounds(mock_view)
                expect_to_draw_targets(mock_view, 5)
                expect_to_draw_panel_preview(mock_view)
                subject.draw(mock_view)
                mock_view.verify
              end
            end
          end
        end
      end
    end
  end
end
