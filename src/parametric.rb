require 'sketchup'
require 'extensions'

module Parametric
	VERSION = '0.0.1'

	unless file_loaded? __FILE__
		loader = File.join('parametric', 'loader.rb')
		Sketchup.register_extension(
			SketchupExtension.new('Parametric', loader).tap do |ext|
				ext.description = 'Parametric lib'
				ext.version = VERSION
				ext.creator = 'mike09 (mike09@mail.ru)'
				ext.copyright = 'mike09 © 2025'
			end,
			true
		)
		file_loaded __FILE__
	end
end
