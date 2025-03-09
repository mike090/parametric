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
		end

		def initialize(**init_params)
			@factory_params = Parametric::Params.new **init_params
		end

		def set_param(name, value = nil, &block)
			@factory_params.set name, value, &block
		end

		def build(environ = nil, **build_params)
			environ ||= Parametric::Environ.new
			@build_params = Params.new(**build_params).expand_with!(@factory_params)
			check_required_params(@build_params)
			environ.unshift(@build_params)
			do_build(environ)
		ensure
			@build_params = nil
			environ.shift
		end

		private

		def params
			@build_params
		end

		# NOTE! Don't use environ to get params for building fatory product 
		# e.g. product.name = environ.name
		# To get values you mast use #params, and use environ only to calculate param value
		# e.g. product.name = params.get :name, environ
		# becouse params it's params for building product, but environ it's environ on wich params values are calculated
		# i hope it's clear ;) 
		def do_build(environ)
			raise 'Abstract method called'
		end

		def check_required_params(params)
			self.class.check_required_params(params)
		end
	end
end
