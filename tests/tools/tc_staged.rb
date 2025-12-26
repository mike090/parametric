require_relative '../test_helper'
require 'parametric/tools/staged'
require 'forwardable'

module Parametric
  module Tools
    module Staged
      module Tests
        extend Spec::TestsRoot

        describe Staged do

          subject do
            tool = Class.new do
              include Staged

              attr_writer :stage
            end.new
            tool.stage = mock_stage
            tool
          end
          let(:mock_stage) { Minitest::Mock.new }
          let(:view) { Sketchup.active_model.active_view }

          it 'redirects respond_to' do
            mock_stage.expect(:activate, true)
            assert subject.respond_to? :activate
          end

          it 'redirects events' do
            mock_stage.expect :activate, true
            Sketchup.active_model.select_tool subject
            assert mock_stage.verify
            mock_stage.expect(:deactivate, true, [view])
            Sketchup.active_model.select_tool nil
            assert mock_stage.verify
          end
        end
      end
    end
  end
end
