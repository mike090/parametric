require_relative '../test_helper'
require 'parametric/tools/decomposition_tool'

module Parametric
  module Tools
    module DecompositionTool
      class TC_Model < TestUp::TestCase

        attr_reader :subject

        def setup
          @subject ||= Model.new
        end

        def test_vectors
          assert_equal [], subject.vectors
          subject.start = ORIGIN
          assert_equal [], subject.vectors
          subject.end = ORIGIN
          assert_equal [], subject.vectors
          subject.end = ::Geom::Point3d.new(2, 3)
          expected = [[2,0], [0,3]].map { |params| ::Geom::Vector3d.new params }
          assert_equal expected, subject.vectors
          subject.end = ::Geom::Point3d.new(2, 3, 4)
          expected = [[2,0], [0,3], [0,0,4]].map { |params| ::Geom::Vector3d.new params }
          assert_equal expected, subject.vectors
        end

        def test_valid
          refute subject.valid?
          subject.start = ORIGIN
          refute subject.valid?
          subject.end = ORIGIN
          refute subject.valid?
          subject.end = ::Geom::Point3d.new(0, 2)
          refute subject.valid?
          subject.end = ::Geom::Point3d.new(2,3)
          assert subject.valid?
          subject.end = ::Geom::Point3d.new(3,4,5)
          assert subject.valid?
        end
      end

      class TC_Tool < TestUp::TestCase

        class Tool
          attr_reader :model
          include DecompositionTool

          def done(view); end
        end

        attr_reader :subject

        def setup
          @subject = Tool.new
          Sketchup.active_model.select_tool @subject
        end

        def teardown
          Sketchup.active_model.select_tool nil
        end

        def view
          Sketchup.active_model.active_view
        end

        def test_view_invalidation
          assert true
        end

        def test_onMouseMove
          subject.onMouseMove(nil, 10, 10, view)
          refute subject.model.start || subject.model.end
          subject.model.start = ORIGIN
          subject.onMouseMove(nil, 10, 10, view)
          assert_instance_of ::Geom::Point3d, subject.model.end
        end

        def test_on_user_text
          subject.onUserText('20;30', view)
          refute subject.model.valid?, "ignore input when first point is'nt defined"
          subject.model.start = ORIGIN
          subject.onUserText('20;30', view)
          refute subject.model.valid?, "ignore input when end point is'nt defined"
          subject.model.end = ::Geom::Point3d.new(5,6)
          subject.onUserText('20;30', view)
          expected = [[20.mm,0], [0,30.mm]].map { |params| ::Geom::Vector3d.new params }
          assert_equal expected, subject.model.vectors, 'set vectos lengths when model is valid'
          subject.reset
          subject.model.start = ::Geom::Point3d.new 2,1
          subject.model.end = ::Geom::Point3d.new(3,4,5)
          subject.onUserText('20;30', view)
          expected = [[1,0], [0,3], [0,0,5]].map { |params| ::Geom::Vector3d.new params }
          assert_equal expected, subject.model.vectors, 'ignore input when lengths count is not equal vectors count'
          subject.onUserText '450;570;720', view
          expected = [[450.mm,0], [0,570.mm], [0,0,720.mm]].map { |params| ::Geom::Vector3d.new params }
          assert_equal expected, subject.model.vectors, 'set vectos lengths when model is 3d'
        end

        def test_on_lButtonDown
          flag = Minitest::Mock.new.expect(:raise, nil)
          subject.define_singleton_method(:done) { |view| flag.raise }
          subject.onMouseMove(nil, 10, 20, view)
          subject.onLButtonDown(nil, 10, 20, view)
          assert_instance_of ::Geom::Point3d, subject.model.start
          assert_nil subject.model.end
          subject.onMouseMove(nil, 50, 70, view)
          assert_instance_of ::Geom::Point3d, subject.model.end
          subject.onLButtonDown(nil, 50, 70, view)
          assert flag.verify
        end

        def test_draw
          refute subject.draw(view)
          subject.onMouseMove nil, 10, 5, view
          refute subject.draw(view)
          subject.onLButtonDown nil, 10, 5, view
          refute subject.draw(view)
          subject.onMouseMove nil, 20, 50, view
          assert subject.draw(view)
          subject.onLButtonDown nil, 20, 50, view
          assert subject.draw(view)
          assert subject.model.valid?
        end

        def test_get_extents
          assert_instance_of ::Geom::BoundingBox, subject.getExtents
          subject.model.start = ORIGIN
          assert_equal ORIGIN, subject.getExtents.min
          assert_equal ORIGIN, subject.getExtents.max
          subject.model.end = ::Geom::Point3d.new(2,3,4)
          assert_equal ::Geom::Point3d.new(2,3,4), subject.getExtents.max
        end

        def test_enable_VCB
          refute subject.enableVCB?
          subject.model.start = ::Geom::Point3d.new 1,2,3
          assert subject.enableVCB?
        end
      end

      class TC_Stage < TestUp::TestCase
        attr_reader :subject

        def setup
          expected_params = { view: Sketchup::View, vertex: ::Geom::Point3d, vectors: Array,  }
          @done_flag = Minitest::Mock.new.expect(:raise, nil, [expected_params])
          flag = @done_flag
          @subject = DecompositionTool.as_stage { |params| flag.raise params.transform_values(&:class) }
          @subject.activate
          @subject
        end

        def test_done
          model = subject.instance_variable_get :@model
          model.start = ORIGIN
          model.end = ::Geom::Point3d.new [2,3]
          subject.onLButtonDown(nil,0,0,Sketchup.active_model.active_view)
          assert @done_flag.verify
        end
      end
    end
  end
end
