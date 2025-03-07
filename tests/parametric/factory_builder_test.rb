require 'minitest/autorun'
require_relative '../../src/parametric/lib/factory'
require_relative '../../src/parametric/lib/factory_builder'

class FactoryBuilderTest < Minitest::Test
	attr_accessor :subject, :factory_class

	def setup
		self.subject = Class.new Parametric::FactoryBuilder
		self.factory_class = Class.new Parametric::Factory
		subject.factory_class factory_class
	end

	def test_factory_class
		factory = subject.build_factory
		assert_instance_of(factory_class, factory)
	end

	def test_block_execution
		subject.singleton_class.attr_accessor :test_attr
		subject.build_factory { self.test_attr = 'test_value' }
		assert_equal 'test_value', subject.test_attr
	end

	def test_with_inital_params
		factory = subject.build_factory color: 'red'
		assert_equal 'red', factory.params.get(:color)
	end

	def test_with_property_as_value
		factory = subject.build_factory() { color :red }
		assert_equal :red, factory.params.get(:color)
	end

	def test_with_invalid_property
		assert_raises do
			subject.build_factory { color? :red }
		end
	end

	def test_with_registred_builder
		transform_factory_class = Class.new Parametric::Factory
		transform_factory_class.define_method(:do_build) { |environ| { transformation: {origin: environ.origin } } }
		transform_factory_builder = Class.new Parametric::FactoryBuilder
		transform_factory_builder.factory_class transform_factory_class
		Parametric.register_builder 'position', transform_factory_builder
		factory_class.define_method(:do_build) { |environ| { some_group: { position: environ.position } } }
		factory = subject.build_factory do
			position { origin [1,0,0] }
		end
		assert_equal({
			some_group: {
				position: { 
					transformation: {
						origin: [1,0,0]
					}
				} 
			}
		}, factory.build)
	end
end