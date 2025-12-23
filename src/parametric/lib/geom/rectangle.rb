require_relative 'polygon'

module Parametric
	module Geom
		class Rectangle
			include Enumerable
			extend Forwardable

			attr_reader :vertex, :vectors

			def_delegators :polygon, :each, :vertices, :edges, :plane, :center, :point_in?

			def initialize(vertex, *vectors)
				raise ArgumentError, 'expeced two perpendicular vectors' unless
					vectors.map(&:class) == [::Geom::Vector3d]*2
				raise TypeError, "vectors aren't valid" unless vectors.all?(&:valid?)
				raise TypeError, "vectors aren't perpendicular" unless vectors.first.perpendicular?(vectors.last) 

				@vertex = vertex
				@vectors = vectors
			end

			def offset(value)
				Rectangle.new *offset_params(value)
			end

			def offset!(value)
				return self if value.is_a?(Numeric) && value.zero?

				@polygon = nil
				new_values = offset_params(value)
				@vertex = new_values.first
				@vectors = new_values[1..]
				self
			end

			def shift(value)
				Rectangle.new @vertex.offset(plane.normal, value), *@vectors
			end

			def shift!(value)
				return if value.is_a?(Numeric) && value.zero?

				vector = plane.normal # self.plane() restores @polygon
				@polygon = nil
				@vertex.offset! vector, value
				self
			end

			def reverse!
				@polygon = nil
				@vectors.rotate!
				self
			end

			def reverse
				Rectangle.new @vertex, *@vectors.rotate
			end

			def ==(rectangle)
				return unless rectangle.instance_of? Rectangle

				@vertex == rectangle.vertex && @vectors == rectangle.vectors
			end

			private

			def offset_params(value)
				offset_values = case value
				when Numeric
					[value]*2
				when String
					match_data = value.match /^1\/(\d)$/
					raise "invalid offset format (expected '1/3', '1/5'..)" unless match_data

					offset_values = @vectors.map { |vector| vector.length / match_data[1].to_i } 
				end
				new_vertex = @vectors.zip(offset_values).
					reduce(@vertex) { |vertex,(vector,len)| vertex.offset vector, len }
				new_vectors = @vectors.zip(offset_values).map do |vector,len|
					vector = vector.clone
					vector.length = vector.length - 2 * len
					vector
				end
				[new_vertex, new_vectors].flatten
			end

			def polygon
				v1,v2 = @vectors
				@polygon ||= Parametric::Geom::Polygon.new([
					@vertex,
					@vertex + v1,
					@vertex + v1 + v2,
					@vertex + v2
				])
				@polygon
			end
		end

    def self.rectangle(vertex, vector)
      vectors = decompose_vector(vector)
      Rectangle.new vertex, *vectors
    end
	end
end
