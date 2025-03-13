assembly 'module_box' do
	description 'Модуль с вкладным дном'
	required_parameters :module_width,
	                    :module_depth,
	                    :module_height,
	                    :panel_thickness
	panel 'left_side' do
		length { module_height }
		width { module_depth }
		position do
			origin { [panel_thickness, 0, 0] }
			length_directed_along Z_AXIS
			width_directed_along Y_AXIS
		end
	end
	panel 'right_side' do
		length { module_height }
		width { module_depth }
		position do
			origin { [module_width, 0, 0] }
			length_directed_along Z_AXIS
			width_directed_along Y_AXIS 
		end
	end
	panel 'bottom' do
		length { module_depth - 16.mm }
		width { module_width - 2 * panel_thickness }
		position do
			origin { [module_width - panel_thickness, 0, 0] }
			length_directed_along Y_AXIS
			width_directed_along X_AXIS.reverse
		end
	end
	panel 'cover' do
		length { module_depth - 16.mm }
		width { module_width - 2 * panel_thickness }
		position do
			origin { [module_width - panel_thickness, 0, module_height - panel_thickness] }
			length_directed_along Y_AXIS
			width_directed_along X_AXIS.reverse
		end
	end
	panel 'back' do
		length { module_height - 2.mm }
		width { module_width - 20.mm }
		panel_thickness { 3.mm }
		position do
			origin { [10.mm, module_depth - 16.mm, 1.mm] }
			length_directed_along Z_AXIS
			width_directed_along X_AXIS
		end 
	end
end
