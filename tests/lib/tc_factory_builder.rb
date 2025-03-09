require "testup/testcase"
require_relative '../../src/parametric/lib/factory'
require_relative '../../src/parametric/lib/factory_builder'

class TC_FactoryBuilder < TestUp::TestCase
	attr_accessor :subject, :factory_class

	def setup
		self.subject = Class.new Parametric::FactoryBuilder
		self.factory_class = Class.new Parametric::Factory
		factory_class.define_method(:do_build) { |environ| params.get :color }
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

	def test_initalize_with_params
		factory = subject.build_factory(color: 'red')
		assert_equal 'red', factory.build
	end

	def test_initialize_with_block
		factory = subject.build_factory() { color :red }
		assert_equal :red, factory.build
	end

	def test_with_invalid_property
		assert_raises do
			subject.build_factory { color? :red }
		end
	end

	def test_with_registred_builder
		pos_factory_class = Class.new Parametric::Factory
		pos_factory_class.define_method(:do_build) { |environ| "at: #{environ.origin}"  }
		pos_factory_builder = Class.new Parametric::FactoryBuilder
		pos_factory_builder.factory_class pos_factory_class
		Parametric.register_builder 'pos_prop', pos_factory_builder
		factory_class.define_method(:do_build) { |environ| { some_group: { position: environ.pos_prop } } }
		factory = subject.build_factory do
			pos_prop { origin [1,0,0] }
		end
		assert_equal({
			some_group: {
				position: 'at: [1, 0, 0]'
			}
		}, factory.build)
	end
end