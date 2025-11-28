module Parametric
  module Geom
    def self.decompose_vector(vector)
      vector.to_a.each_with_index.map { |len, index| ::Geom::Vector3d.new [0,0].insert(index, len) }
    end
  end
end
