require 'testup/testcase'
require_relative '../../src/parametric/factories/pionter_factory'

class TC_PanelFactory < TestUp::TestCase
	attr_accessor :_test_geometry

	def teardown
    _test_geometry.erase! if _test_geometry
  end

  def test_draw_pointer
  	point = [1,1,0]
  	normal = Z_AXIS
  	v
  end
 end