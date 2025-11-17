module Parametric
  module Geom
    def self.decompose_vector(vector)
      vector.to_a.each_with_index.map do |value, index|
        params = [0,0,0]
        params[index] = value
        ::Geom::Vector3d.new(params)
      end
    end
  end
end