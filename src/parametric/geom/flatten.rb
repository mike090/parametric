require_relative 'polygon'
module Parametric
  module Geom
    class Parametric::Geom::Flatten

      attr_reader :faces

      def initialize(profile, vector)
        profile = Parametric::Geom::Polygon.new profile.to_a

        raise TypeError, 'vector on profile plane' if profile.plane.normal.perpendicular?(vector)

        profile.reverse! if profile.plane.normal.angle_between(vector) < 90.degrees

        @profile = profile.to_a
        @vector = vector
      end

      def vertices
        @profile + @profile.map { |corner| corner + @vector }
      end

      def edges
        opposite = @profile.map { |corner| corner + @vector }
        (@profile.zip(opposite) + @profile.zip(@profile.rotate) + opposite.zip(opposite.rotate)) #.map { |p1, p2| [p1, p2 - p1] }
      end

      def profile_sides
        @faces ||= [
          Polygon.new(@profile),
          Polygon.new(@profile.map { |corner| corner + @vector }.rotate!.reverse!)
        ]
      end

      def edge_sides
        edges = @profile.map { |corner| [corner, corner + @vector] }
        edges.zip(edges.rotate).map { |(p1, p2), (p4, p3)| Polygon.new p1, p2, p3, p4 }
      end

      def sides
        profile_sides + edge_sides
      end

      def bounds
        @bb ||= ::Geom::BoundingBox.new.tap do |bb|
          vertices.each { |vertex| bb.add vertex }
        end
      end

      def inspect
        "#{super.match(/^[^\s]+/)[0]}>"
      end
    end
  end
end
