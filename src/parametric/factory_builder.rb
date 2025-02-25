module Parametric
	class << self
		def register_builder(builder_name, builder)
	  	builders[builder_name.to_sym] = builder
	  end

	  def find_builder(builder_name)
	  	builders[builder_name.to_sym]
	  end

	  def list_builders
	  	builders.keys
	  end

	  private

	  def builders
	  	@builders ||= {}
	  end
	end

	class FactoryBuilder
		class << self
			def factory_class(a_factory_class)
				@factory_class = a_factory_class
			end

			def build_factory( **init_params, &blk)
				@factory = @factory_class.new **init_params
				class_eval &blk if block_given?
				@factory
			end

			def method_missing(method_name, *args, &blk)
				builder = Parametric.find_builder method_name
				if builder
					factory = builder.build_factory(&blk)
					@factory.params.set(method_name) { factory.build(self) }
				else
					if method_name.match /^[a-zA-Z_]+$/
						@factory.params.set method_name, args.first, &blk
					else
						raise "Unknown builder #{method_name} or invalid factory param name"
					end
				end
			end
		end
	end
end