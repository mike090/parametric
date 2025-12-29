module Parametric
  module Geom
    class Box

      def initialize(*params)
        case params.map(&:class)
        when [::Geom::Point3d, ::Geom::Vector3d]
          initialize params.first, *Geom.decompose_vector(params.last)
        when [::Geom::Point3d, [::Geom::Vector3d] * 3].flatten
          @vertex = params.first
          @vectors = regularize_vectors params.last(3)
        else
          raise ArgumentError, 'expected Point3d and one or three Vector3d'
        end
      end

      def inspect
        "#{super.match(/^[^\s]+/)[0]} #{[@vertex, @vectors].flatten.inspect}>"
      end

      def sides
        @sides ||= begin
          v1,v2,v3 = @vectors
          base = Rectangle.new @vertex, v2, v1
          [base,
          Rectangle.new(@vertex + v1 + v2 + v3, v1.reverse, v2.reverse)] + 
          base.edges.map { |p0, p1| Rectangle.new p1, p1.vector_to(p0), v3 }
        end
      end

      def vertices
        @vertices ||= begin
          v1,v2,v3 = @vectors
          [
            vertex = @vertex, vertex + v3,
            vertex = @vertex + v1, vertex + v3,
            vertex = @vertex + v1 + v2, vertex + v3,
            vertex = @vertex + v2, vertex + v3 
          ]
        end
      end

      def edges
        @edges ||= begin
          @vectors.combination(2).to_a.unshift([]).map do |pair|
            vertex = ([@vertex] + pair).reduce(&:+)
            vectors = @vectors - pair + pair.map(&:reverse)
            vectors.map { |vector| [vertex, vertex + vector] }
          end.reduce(&:+)
        end
      end

      def bounds
        bb = ::Geom::BoundingBox.new
        bb.add vertices
        bb
      end

      def connected(vertex)
        edges.select { |edge| edge.include? vertex }.flatten.
          reject { |point| point == vertex }
      end

      def center
        @center ||= begin
          vts = vertices.map(&:to_a)
          pos = vts[0].zip(*vts[1..]).map { |vals| vals.reduce(&:+)/vals.length }
          ::Geom::Point3d.new pos
        end
      end

      def params
        [@vertex, @vectors].flatten.map(&:clone)
      end

      private

      # sets the outside direction of the box's sides normals
      def regularize_vectors(vectors)
        v1, v2, v3 = vectors
        rtn_90 = ::Geom::Transformation.rotation(ORIGIN, v3, 90.degrees)
        vectors[0], vectors[1] = vectors[1], vectors[0] unless v1.transform(rtn_90).samedirection? v2
        vectors
      end
    end
  end
end
