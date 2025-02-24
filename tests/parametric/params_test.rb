require 'minitest/autorun'
require_relative '../../src/parametric'

class ParamsTest < Minitest::Test
	
	attr_accessor :subject

	def setup
		self.subject = Parametric::Params.new	
	end
	
	def test_can_keep_param
		subject.set :color, 'red'
		assert_equal('red', subject.get('color'))
	end

	def test_defined
		subject.set :color, 'red'
		assert subject.defined? 'color'
		refute subject.defined? 'shape'
	end

	def test_proc_value
		subject.set('class') { self.class }
		assert_equal Object, subject.get(:class, Object.new)
	end

	def test_set_without_value_and_block_raises
		e = assert_raises { subject.set 'color' }
		assert_match 'mast be specify', e.message
	end

	def test_set_value_and_block_raises
		e = assert_raises { subject.set('color', :red) { 'blue' } }
		assert_match 'either an value or a block', e.message
	end

	def test_with_proc_value
		subject.set(:color, proc { 'red' })
		assert_equal 'red', subject.get('color')
	end

	def test_init_params
		assert_equal 'red', Parametric::Params.new('color' => 'red').get(:color)
	end

	def test_unknown_param_raises
		e = assert_raises { subject.get :color }
		assert_match 'Unknown param', e.message
	end
end
