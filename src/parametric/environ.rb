require 'forwardable'

module Parametric
	class Environ
		extend Forwardable

		def_delegators :params_store, :shift, :unshift

		def method_missing(method_name)
			match = method_name.to_s.match(/([a-zA-Z_]+)([?]?)$/)
			raise NoMethodError, "undefined method #{method_name}" unless match

			param_name = match[1].to_sym
			params = find_params param_name
			case match[2]
			when '?'
				!!params
			else
				raise "Unknown param #{param_name}" unless params

				raise 'Cyclic dependency detected' if queue.include? param_name
				
				queue << param_name
				value = params.get param_name, self
				queue.pop
				value
			end
		end

		def defined?(param_name)
			!!find_params(param_name.to_sym)
		end

		private

		def params_store
			@params_store ||= []
		end

		def find_params(param_name)
			params_store.find { |params| params.defined? param_name }		
		end

		def queue
			@queue ||= []
		end
	end	
end
