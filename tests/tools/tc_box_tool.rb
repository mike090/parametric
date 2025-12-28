require_relative '../test_helper'
require_relative '../support/tools_helper'
require 'parametric/tools'

module Parametric
  module Tools
    module BoxTool
      module Tests
        extend Spec::TestsRoot

        describe BoxTool do
          test_helpers Tools::Helpers

          let(:view) { Sketchup.active_model.active_view }
          let(:decomposition_tool) { mock_tool(decomposition_stage_result) }
          let(:profile) do
            [
              ::Geom::Point3d.new(0,0),
              ::Geom::Point3d.new(10,0),
              ::Geom::Point3d.new(10,20),
              ::Geom::Point3d.new(0,20)
            ]
          end
          let(:push_pull_tool) { mock_tool(push_pull_stage_result, profile) }
          let(:push_pull_stage_result) do
            {
              view: view,
              vector: ::Geom::Vector3d.new(0, 0, 30)
            }
          end
          let(:decomposition_stage_result) do
            {
              view: view,
              vertex: ORIGIN,
              vectors: Geom.decompose_vector(ORIGIN.vector_to([10,20,30]))
            }
          end
          
          before do
            @truly_decomposition = Tools.set_default(:decomposition_tool, decomposition_tool)
            @truly_push_pull = Tools.set_default(:push_pull_tool, push_pull_tool)
          end

          after do
            Tools.set_default(:decomposition_tool, @truly_decomposition)
            Tools.set_default(:push_pull_tool, @truly_push_pull)
          end

          describe 'workflow' do

            subject do
              tool_fixture(BoxTool)
            end

            before do
              subject.activate
            end

            context 'when first stage returns flat' do

              test_case_name 'TC_using_push_pull'

              let(:decomposition_stage_result) do
                {
                  view:,
                  vertex: ORIGIN,
                  vectors: [::Geom::Vector3d.new(10, 0, 0), ::Geom::Vector3d.new(0, 20, 0)]
                }
              end
              
              it 'uses decomposition tool' do
                expect(decomposition_tool).must_be :used?
              end

              it 'uses push_pull_tool' do
                expect(push_pull_tool).must_be :used?
              end
            end

            context 'when first stage directly returns box' do
              let(:decomposition_stage_result) do
                {
                  view: view,
                  vertex: ORIGIN,
                  vectors: Geom.decompose_vector(ORIGIN.vector_to([10,20,30]))
                }
              end

              test_case_name 'TC_skiping_push_pull'
              
              it 'uses decomposition tool' do
                expect(decomposition_tool).must_be :used?
              end

              it 'skips push_pull_tool' do
                expect(push_pull_tool).must_be :unused?
              end
            end  
          end

          describe '.as_stage' do

            test_case_name 'TC_stage'

            subject do
              BoxTool.as_stage { |params| done_flag.call params.transform_values(&:class) }
            end
            let(:done_flag) { Minitest::Mock.new.expect(:call, nil, [expected_callback_params]) }
            let(:expected_callback_params) do
              { 
                view: Sketchup::View,
                vertex: ::Geom::Point3d,
                vectors: Array
              }
            end

            it 'returns Stage instance' do
              expect(subject).must_be_instance_of Parametric::Tools::BoxTool::Stage
            end

            it 'activation makes callback with expected params' do
              subject.activate
              done_flag.verify
            end
          end
        end  
      end
    end
  end
end
