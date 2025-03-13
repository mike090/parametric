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

	def test_factory_params_overloading
		environ = Parametric::Environ.new
		environ.unshift(Parametric::Params.new shape_color: :red)
		factory_class = Class.new Parametric::Factory
		factory_class.define_method(:do_build) do
			"color: #{param :color}"
		end
		assert_equal 'color: red', factory_class.new(color: proc { shape_color }).build(environ)
		assert_equal 'color: blue', factory_class.new(color: :green).build(environ, color: :blue)
	end

	def test_required_params_checking
		factory_class = Class.new Parametric::Factory
		factory_class.required_params :color
		factory_class.define_method(:do_build) { 'rectangle' }
		e = assert_raises { factory_class.new.build }
		assert_match 'missing', e.message
	end

	def test_clear_build_params
		factory_class = Class.new Parametric::Factory
		factory_class.define_method(:do_build) { color }
		factory_class.define_param_readers :color
		factory = factory_class.new
		assert_equal 'red', factory.build(color: 'red')
		assert_equal 'blue', factory.build(color: 'blue')
	end
end