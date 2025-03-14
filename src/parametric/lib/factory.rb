require_relative 'params'
require_relative 'environ'

module Parametric
	class Factory
		class << self
			def required_params *keys
				if keys.empty?
					return (@required_params || []) if superclass == Parametric::Factory
					superclass.required_params + (@required_params || [])
				else
					@required_params = keys
				end
			end

			def check_required_params(params)
				missing = required_params.reject { |param| params.defined? param }
				raise "Required params #{missing.join ', '} missing" unless missing.empty?
			end

			def define_param_readers(*params)
				params.each do |param_name|
					define_method(param_name) do 
						param(param_name)
					end
				end
			end
		end

		def initialize(**init_params)
			init_params.each { |param_name, param_value| set_param param_name, param_value }
		end

		def set_param(name, value = nil, &block)
			factory_params.set name, value, &block
		end

		def build(environ = nil, **build_params)
			@environ = environ || Parametric::Environ.new
			@build_params = Params.new(**build_params).expand_with!(factory_params)
			@environ.unshift(@build_params)
			check_required_params
			do_build
		ensure
			clear!
		end

		private

		def clear!
			@build_params = nil
			@environ.shift
		end

		def factory_params
			@factory_params ||= Parametric::Params.new
		end

		def param(name)
			@build_params.get name, @environ
		end

		def params
			@build_params
		end

		# NOTE! Don't use @environ to get params for building fatory product 
		# e.g. product.name = @environ.name
		# To get values you mast use param reader or #param
		# e.g. product.name = param :name
		# becouse param it's factory param for building product, but environ it's environ on wich params values are calculated
		# i hope it's clear ;) 
		def do_build
			raise 'Abstract method called'
		end

		def check_required_params
			self.class.check_required_params(params)
		end
	end
end
