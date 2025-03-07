require "testup/testcase"
require_relative '../../src/parametric/lib/params'
require_relative '../../src/parametric/lib/environ'
require_relative '../../src/parametric/lib/factory'

class TC_Factory < TestUp::TestCase
	def test_requered_params_inheritance
		base_factory_class = Class.new Parametric::Factory
		base_factory_class.required_params :color
		child_factory_class = Class.new base_factory_class
		child_factory_class.required_params :shape
		assert_includes child_factory_class.required_params, :color
		assert_includes child_factory_class.required_params, :shape
	end

	def test_build_params
		environ = Parametric::Environ.new
		environ.unshift(Parametric::Params.new color: :red)
		factory_class = Class.new Parametric::Factory
		factory_class.define_method(:do_build) do |environ|
			"color: #{environ.color}, shape: #{environ.shape}, size: #{environ.size}"
		end
		factory = factory_class.new shape: :rect
		data = factory.build(environ, size: :medium)
		assert_equal 'color: red, shape: rect, size: medium', data
	end

	def test_params_overloading
		environ = Parametric::Environ.new
		environ.unshift(Parametric::Params.new color: :red)
		factory_class = Class.new Parametric::Factory
		factory_class.define_method(:do_build) do |environ|
			"color: #{environ.color}"
		end
		assert_equal 'color: red', factory_class.new.build(environ)
		assert_equal 'color: green', factory_class.new(color: :green).build(environ)
		assert_equal 'color: blue', factory_class.new(color: :green).build(environ, color: :blue)
	end

	def test_required_params_checking
		factory_class = Class.new Parametric::Factory
		factory_class.required_params :color
		factory_class.define_method(:do_build) { |environ| 'rectangle' }
		e = assert_raises { factory_class.new.build }
		assert_match 'missing', e.message
	end
end