require 'testup/testcase'
require_relative '../../src/parametric/factories/panel_factory'

class TC_PanelFactory < TestUp::TestCase
	attr_accessor :temp_geometry

	def teardown
    temp_geometry.erase! if temp_geometry
  end
	
	def test_build_panel
		factory = Parametric::PanelFactory.new length: 100.mm, width: 50.mm, thikness: 18.mm
		self.temp_geometry = factory.build name: 'test_panel'
		assert_instance_of Sketchup::Group, temp_geometry
		assert_equal 'test_panel', temp_geometry.name
		assert temp_geometry.manifold?
		assert_equal 6, temp_geometry.entities.grep(Sketchup::Face).count
		edges = temp_geometry.entities.grep(Sketchup::Edge)
		assert_equal 12, edges.count
		assert [18.mm,50.mm,100.mm], edges.map(&:length).uniq.sort
	end
end