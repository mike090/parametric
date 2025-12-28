module Parametric
  module Geom
    def self.decompose_vector(vector)
      raise ArgumentError, 'Geom::Vector3d expected' unless vector.instance_of?(::Geom::Vector3d)

      vector.to_a.each_with_index.map do |len, index|
        ::Geom::Vector3d.new [0,0].insert(index, len)
      end.select(&:valid?)
    end
  end
end

class ::Geom::Transformation
  def ==(transformation)
    transformation.instance_of?(::Geom::Transformation) &&
      [self.origin, self.xaxis, self.yaxis, self.zaxis] ==
        [transformation.origin, transformation.xaxis,
          transformation.yaxis, transformation.zaxis]
  end
end
