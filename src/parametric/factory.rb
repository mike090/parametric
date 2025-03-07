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

			def check_required_params(environ)
				missing = required_params.reject { |param| environ.defined? param }
				raise "Required params #{missing.join ', '} missing" unless missing.empty?
			end
		end

		def initialize(**init_params)
			@params = Params.new **init_params
		end

		def params
			@params ||= Params.new
		end

		def build(environ = nil, **build_params)
			environ ||= Environ.new
			environ.unshift(params)
			environ.unshift(Params.new **build_params) if build_params.any?
			check_required_params(environ)
			do_build(environ)
		ensure
			environ.shift
			environ.shift if build_params.any?
		end

		private

		def do_build(environ)
			raise 'Abstract method called'
		end

		def check_required_params(environ)
			self.class.check_required_params(environ)
		end
	end
end
