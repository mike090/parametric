require 'minitest/autorun'
require_relative '../../src/parametric'

class EnvironTest < Minitest::Test

	attr_accessor :subject
	
	def setup
		self.subject = Parametric::Environ.new
	end

	def test_param_read
		params = Parametric::Params.new
		params.set 'color', :red
		subject.unshift params
		params = Parametric::Params.new
		params.set 'shape', 'rect'
		subject.unshift params
		assert_equal :red, subject.color
		assert_equal 'rect', subject.shape
	end

	def test_param?
		params = Parametric::Params.new
		params.set 'color', :red
		subject.unshift params
		assert subject.color?
		# assert_instance_of Object, subject
		refute subject.shape?
	end

	def test_override
		params = Parametric::Params.new
		params.set 'color', :red
		subject.unshift params

		params = Parametric::Params.new
		params.set 'color', :green
		subject.unshift params

		assert_equal :green, subject.color
	end

	def test_calculated_param
		params = Parametric::Params.new
		params.set 'color', :red
		subject.unshift params
		params = Parametric::Params.new
		params.set('assertion') { "color is #{color}" }
		subject.unshift params
		assert_equal 'color is red', subject.assertion
	end

	def test_unknown_param_raises
		params = Parametric::Params.new
		params.set :color, :red
		subject.unshift params
		e = assert_raises { subject.shape }
		assert_match 'Unknown param', e.message
	end

	def test_cyclic_dependency_raises
		params = Parametric::Params.new
		params.set(:color) { :red if shape == :rect }
		params.set(:shape) { :rect if color == :green }
		subject.unshift params
		e = assert_raises { subject.color }
		assert_match 'Cyclic dependency', e.message
	end

	def test_defined
		params = Parametric::Params.new
		params.set :color, :red
		subject.unshift params
		assert subject.defined? 'color'
		refute subject.defined? 'shape'
	end
end