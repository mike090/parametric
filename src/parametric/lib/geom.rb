module Parametric
  module Geom
    def self.decompose_vector(vector)
      raise ArgumentError, 'Geom::Vector3d expected' unless vector.instance_of?(::Geom::Vector3d)

      vector.to_a.each_with_index.map do |len, index|
        ::Geom::Vector3d.new [0,0].insert(index, len)
      end.select(&:valid?)
    end

    def self.points_planar?(*points)
      return if points.length < 3

      plane = ::Geom.fit_plane_to_points *points
      return unless points[3..-1].all? { |point| point.on_plane? plane }

      plane
    end
  end
end

class Geom::Transformation
  def ==(transformation)
    transformation.instance_of?(::Geom::Transformation) && self.to_a == transformation.to_a
  end
end
