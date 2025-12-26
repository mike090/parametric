require_relative '../test_helper'
require 'parametric/tools/push_pull_tool'

module Parametric
  module Tools
    module PushPullTool
      class TC_Model < TestUp::TestCase
        def test_test_plane
          profile = Geom::Polygon.new([[1,1], [3,3,1], [1,5]].map { |params| ::Geom::Point3d.new params })
          model = PushPullTool::Model.new profile
          subject = model.test_plane
          assert_nil subject.intersect([profile.first, model.profile.plane.normal])
          assert profile.center.on_plane? subject
        end
      end

      class TC_Tool < TestUp::TestCase
        
        attr_reader :subject

        class Tool
          include PushPullTool
          attr_reader :model

          def done(view); end
        end

        def view
          Sketchup.active_model.active_view
        end

        def setup
          profile = [[1,1], [3,3,1], [1,5]].map { |params| ::Geom::Point3d.new params }
          @subject = Tool.new
          @subject.profile = profile
          Sketchup.active_model.select_tool @subject
        end

        def teardown
          Sketchup.active_model.select_tool nil
        end

        def test_draw
          assert_nil subject.draw(view) # test draw do'nt raises
          subject.model.vector = subject.model.profile.plane.normal
          assert_nil subject.draw(view)
          subject.model.vector = Z_AXIS
          assert_nil subject.draw(view)
        end

        def test_onMouseMove
          assert_nil subject.model.vector
          subject.onMouseMove(nil,10,10,view)
          assert_instance_of ::Geom::Vector3d, subject.model.vector
        end

        def test_on_lButtonDown
          done_flag = Minitest::Mock.new.expect(:raise, nil, [::Geom::Vector3d])
          subject.define_singleton_method(:done) { |view| done_flag.raise @model.vector.class }
          subject.onMouseMove(nil,10,10,view)
          subject.onLButtonDown(nil,10,10,view)
          assert done_flag.verify
        end
      end

      class TC_Stage < TestUp::TestCase
        def test_done
          expected_params = [{view: Sketchup::View, vector: ::Geom::Vector3d }]
          done_flag = Minitest::Mock.new.expect(:raise, nil, expected_params)
          profile = [[0,0], [1,0], [0,1]].map { |params| ::Geom::Point3d.new params }
          subject = PushPullTool.as_stage(profile) { |params| done_flag.raise params.transform_values(&:class) }
          subject.activate
          view = Sketchup.active_model.active_view
          subject.onMouseMove(nil,10,10,view)
          subject.onLButtonDown(nil,10,10,view)
          assert done_flag.verify
        end
      end
    end
  end
end
