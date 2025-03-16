module Parametric
	module Maps
		class HingeCup
			attr_reader :cup_center, :cup_fixes

			def initialize(a_cup_center, *a_cup_fixes)
				@cup_center = a_cup_center
				@cup_fixes = a_cup_fixes
			end
		end
	end
end