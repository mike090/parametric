require 'testup/testcase'
require_relative '../../src/parametric/factories/hinge_cup_drilling'

class TC_HingeCupDrilling < TestUp::TestCase
	attr_accessor :_test_entity

	def teardown
    _test_entity.erase! if _test_entity
  end

	def test_build_with_default_params
		self._test_entity = Parametric::HingeCupDrilling.new.build bore: 4.mm, hinge_map: '45x9.5'
		assert_instance_of Sketchup::Group, _test_entity
		assert_equal 'Hinge cup drilling', _test_entity.name
		assert_equal 3, _test_entity.entities.count
		assert _test_entity.entities.all?(Sketchup::Group)
		drill_positions = _test_entity.entities.map { |drl| drl.transformation.origin.to_a }
		assert drill_positions.include?([0,21.5.mm,0])
		assert drill_positions.include?([-22.5.mm,31.mm,0])
		assert drill_positions.include?([22.5.mm,31.mm,0])
	end
end