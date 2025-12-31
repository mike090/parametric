require_relative 'geom'
require_relative 'tools'


menu = UI.menu('Extensions').add_submenu 'Parametric'
menu.add_item('Cabinet tool') { Parametric::Tools::CabinetTool.use }
