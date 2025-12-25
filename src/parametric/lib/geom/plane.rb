module Parametric
  module Geom
    class Plane < Array
      def initialize(params)
        # [Geom::Point3d.new(1,1,1), ::Geom::Vector3d.new(1,0,0)].flatten returns [Geom::Point3d.new(1,1,1), ::Geom::Vector3d.new(1,0,0)].flatten
        # [Geom::Point3d.new(1,1,1), ::Geom::Vector3d.new(1,0,0)].flatten! returns nil !

        case params.map(&:class)
        when [::Geom::Point3d, ::Geom::Vector3d] # from point and vector
          vector = params.last
          projection_to_origin = ORIGIN.project_to_plane(params).vector_to(ORIGIN)
          raw = vector.normalize.to_a
          raw << (projection_to_origin.valid? &&
            projection_to_origin.samedirection?(vector) ? projection_to_origin.length : -1 * projection_to_origin.length)
          super raw
        when [Float] * 4, [Integer] * 4 # from raw
          raise TypeError, 'Invalid raw data' unless params.all?(Numeric) && ::Geom::Vector3d.new(params.first(3)).unitvector?

          super params.map(&:to_f)
        when [::Geom::Point3d, [::Geom::Vector3d]*2].flatten # from point and two vectos
          point, v1, v2  = params
          initialize [point, point + v1, point + v2]
        else
          flatten = params.flatten
          case flatten.map(&:class)
          when [::Geom::Point3d] * 2 << ::Geom::Vector3d # from point and ray
            flatten[-1] = flatten[-2] + flatten[-1]
            initialize flatten
          else
            if flatten.all? ::Geom::Point3d # from point and edge (line) or from points
              raw = Geom.points_planar? *flatten
              raise TypeError, 'Points are not planar' unless raw

              super raw
            else
              raise TypeError, "Unexpected params: #{params.map(&:class)}"
            end
          end
        end
      end

      def normal
        ::Geom::Vector3d.new first(3)
      end

      def reverse
        Plane.new(normal.reverse.to_a << -1 * last)
      end

      def internal_position(point)
        raise TypeError, "point #{point.inspect} are not on plane #{self}" unless point.on_plane?(self)

        point.transform transformation_2d.inverse
      end

      def parallel?(plane)
        normal.parallel? plane.normal
      end

      def intersect(object)
        case object
        when Plane
          ::Geom.intersect_plane_plane(self, object)
        when Array
          case object.map(&:class)
          when [::Geom::Point3d,::Geom::Vector3d], [::Geom::Point3d]*2
            ::Geom.intersect_line_plane object, self
          else
            raise_intersect_object_type_error object
          end
        else
          raise_intersect_object_type_error object
        end
      end

      def inspect
        "Plane(#{super})"
      end

      private

      def transformation_2d
        @transformation_2d ||= ::Geom::Transformation.new(ORIGIN.project_to_plane(self), normal)
      end

      def raise_intersect_object_type_error(object)
        raise TypeError, "impossible to intersect plane with an object #{object}"
      end
    end
  end
end
