module Parametric
	class Params
		def initialize(**init_params)
			init_params.each { |k,v| set k, v }
		end

		def get(name, environ = nil)
			param = store[name.to_sym]
			raise "Unknown param #{name}" unless param
			param.value(environ)
		end

		def set(name, value = nil, &blk)
			raise "A value or block mast be specify to define #{name}" unless value or blk
			raise "Specify either an value or a block (not both) to define #{name}" if value and blk
			param ||= ProcParam.new(blk) if blk
			param ||= ProcParam.new(value) if value.instance_of? Proc
			param ||= value ? ValueParam.new(value) : ProcParam.new(blk)
			store[name.to_sym] = param
		end

		def defined?(name)
			store.include? name.to_sym
		end

		private

		def store
			@store ||= {}
		end
	end

	class ValueParam
		def initialize(value = nil)
			@value = value
		end

		def value(environ = nil)
			@value
		end
	end

	class ProcParam
		def initialize(calculator)
			@calculator = calculator
		end

		def value(environ)
			environ.instance_eval &@calculator
		end
	end
end