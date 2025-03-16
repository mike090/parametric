require 'testup/testcase'
require_relative '../../src/parametric/factories/hinge_cup_mapper'
require_relative '../../src/parametric/models/maps/hinge_cup'

class TC_HingeCupMapper < TestUp::TestCase
	def test_created_map
		cup_map = Parametric::HingeCupMapper.new.build(bore: 4.mm, map: '52x5.5')
		assert_instance_of Parametric::Maps::HingeCup, cup_map
		assert_equal [0, 21.5.mm, 0], cup_map.cup_center.to_a
		assert cup_map.cup_fixes.map(&:to_a).include?([-26.mm, 27.mm, 0.mm])
		assert cup_map.cup_fixes.map(&:to_a).include?([26.mm, 27.mm, 0.mm])
	end

	def test_invalid_map_raises
		e = assert_raises { Parametric::HingeCupMapper.new(bore: 4, map: 'fake') }
		assert_match 'fake', e.message
	end

	def test_with_regular_params
		assert_instance_of Parametric::Maps::HingeCup,
			Parametric::HingeCupMapper.new.build(
				bore: 4.mm,
				interfixes_distance: 45.mm,
				cup_fixes_offset: 9.5
			)
	end
end