require 'testup/testcase'
require_relative '../../src/parametric/factories/assembly_factory'
require_relative '../../src/parametric/factories/panel_factory'
require_relative '../../src/parametric/factories/drilling_factory'

class TC_AssemblyFactory < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
    _test_entity.erase! if _test_entity
  end

	def test_build_assembly
		factory = Parametric::AssemblyFactory.new(
			x: 570.mm, 
			y: 450.mm,
			panel_thikness: 16.mm
		)

		factory.use panel_factory
		factory.use drilling_factory
		self._test_entity = factory.build drilling_pos: [37.mm, 8.mm, 16.mm]

		assert_instance_of Sketchup::Group, _test_entity
		assert _test_entity.entities.grep(Sketchup::Group).one? { |group| group.name.match 'Panel' }
		assert _test_entity.entities.grep(Sketchup::Group).one? { |group| group.name.match 'Drilling' }
	end

	private

	def panel_factory
		@panel_factory ||= Parametric::PanelFactory.new(
			length: proc { x }, 
			width: proc { y },
			thikness: proc { panel_thikness }
		)
	end

	def drilling_factory
		@drilling_factory ||= Parametric::Drilling.new(
			diameter: 8.mm,
			depth: 13.mm,
			normal: Z_AXIS.reverse,
			position: proc { Geom::Transformation.new drilling_pos }
		)
	end
end