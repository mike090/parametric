require 'testup/testcase'
require_relative '../../src/parametric/factories/assembly_factory'
require_relative '../../src/parametric/factories/panel_factory'
require_relative '../../src/parametric/factories/drilling_factory'

class TC_AssemblyFactory < TestUp::TestCase
	attr_accessor :_test_geometry

	def teardown
    _test_geometry.erase! if _test_geometry
  end

	def test_build_assembly
		factory = Parametric::AssemblyFactory.new(
			x: 100.mm, 
			y: 100.mm,
			panel_thikness: 16.mm
		)

		factory.use Parametric::PanelFactory.new(
			length: proc { x }, 
			width: proc { y },
			thikness: proc { panel_thikness }
		)

		factory.use Parametric::DrillingFactory.new(
			diameter: 8.mm,
			depth: 13.mm,
			normal: Z_AXIS.reverse,
			position: proc { Geom::Transformation.new drilling_pos }
		)

		self._test_geometry = factory.build drilling_pos: [37.mm, 34.mm, 16.mm]
		assert_instance_of Sketchup::Group, _test_geometry
	end
end