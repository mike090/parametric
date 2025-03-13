require 'testup/testcase'
require_relative '../../src/parametric/factories/panel_factory'

class TC_PanelFactory < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
    _test_entity.erase! if _test_entity
  end
	
	def test_build_panel
		factory = Parametric::PanelFactory.new length: 100.mm, width: 50.mm, thikness: 18.mm
		self._test_entity = factory.build name: 'test_panel'
		assert_instance_of Sketchup::Group, _test_entity
		assert_equal 'test_panel', _test_entity.name
		assert _test_entity.manifold?
		assert_equal 6, _test_entity.entities.grep(Sketchup::Face).count
		edges = _test_entity.entities.grep(Sketchup::Edge)
		assert_equal 12, edges.count
		assert [18.mm,50.mm,100.mm], edges.map(&:length).uniq.sort
	end
end