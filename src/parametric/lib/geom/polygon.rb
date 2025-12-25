require_relative 'plane'

module Parametric
  module Geom
    class Polygon < Array
      def self.from_face(face)
        new face.vertices.map(&:position)
      end

      # Полигон это масив трех и более точек, лежащих на одной плоскости
      def initialize(*vertices)

        vertices = vertices.first if (vertices.length == 1)
        raise TypeError, "wrong argument type #{vertices.class} (expected Array of points)" unless
                  vertices.is_a?(Array) && vertices.all?(::Geom::Point3d)

        raise ArgumentError, 'At least three points needed to initialize polygon' if vertices.length < 3

        plane = Geom.points_planar? *vertices
        raise ArgumentError, 'the vertices do not lie in the same plane' unless plane

        super vertices
      end

      # Стороны полигона
      #
      # @return [Array(Array(Geom::Point3d, Geom::Point3d))]
      def edges
        self.zip(self.rotate)
      end

      # Смещает полигон

      # @param vector [Geom::Vector3d] направление смещения
      # @param distance [Numeric] дистанция смещения
      # @return [Parametric::Geom::Polygon] новый полигон
      def shift(vector, distance = vector.length)
        Parametric::Geom::Polygon.new self.map { |vertex| vertex.offset vector, distance }
      end

      # Плоскость полигона

      # @return [Parametric::Geom::Plane] плоскость
      def plane
        Parametric::Geom::Plane.new self
      end

      # Возвращает новый полигон с отступом (offset) наружу или во внутрь (в зависимости от знака параметра distance)
      #
      # @param distance [Numeric] значение смещения
      # @param keep_vertices_count [true, false] сохранять соличество вершин (в случае если три вершины лежат на одной стороне)
      # @return [Parametric::Geom::Polygon] полигон
      def offset(distance, keep_count = false)
        return Parametric::Geom::Polygon.new(self) if distance.zero?

        angle = distance.negative? ? 90.degrees : -90.degrees
        rotation = ::Geom::Transformation.rotation(ORIGIN, plane.normal, angle)
        guides = edges.map do |p1, p2|
          edge_vector = p2 - p1
          offset_vector = edge_vector.transform(rotation)
          [p1.offset(offset_vector, distance.abs), edge_vector.normalize]
        end
        intersections = guides.rotate(-1).zip(guides).map do |line1, line2|
          ::Geom.intersect_line_line(line1, line2) || (line2.first if keep_count)
        end.compact
        Parametric::Geom::Polygon.new intersections
      end

      # Возвращает новый многоугольник с инвертированной плоскостью
      #
      # @return [Parametric::Geom::Polygon]
      def reverse
        Polygon.new super.rotate(-1)
      end

      # Переворачивает плоскость многоугольника
      #
      # @return self
      def reverse!
        super.rotate!(-1)
        # self.rotate!.reverse!
      end

      def vertices
        Array.new self
      end

      # Центр многоугольника
      #
      # @return [Geom::Point3d]
      def center
        ::Geom::Point3d.new [0,0,0].zip(* vertices.map(&:to_a)).map { |ary| ary.sum / (ary.length - 1) }
      end

      # Проверяет находится ли точка внутри многоугольника
      #
      # @param point [Geom::Point3d] тестируемая точка
      # @param check_border [TrueClass, FalseClass] учитывать стороны многоугольника
      # @return [TrueClass, FalseClass] результат тестирования
      def point_in?(point, check_border = false)
        point.on_plane?(plane) &&
          ::Geom.point_in_polygon_2D(plane.internal_position(point), self.map { |pnt| plane.internal_position(pnt) }, check_border)
      end

      def inspect
        "<#{self.class} #{super}>"
      end
    end
  end
end
