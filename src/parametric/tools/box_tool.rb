require_relative '../lib/geom/box'

module Parametric::Tools::BoxTool
  # helps to define a virtual box

  def self.as_stage(transformation = IDENTITY, &when_done)
    @when_done = when_done

    using :xyz_tool, transformation do |point, vectors|
      if is_3d?(point, vectors)
        done(point, vectors)
      else
        using :push_pull_tool, rectangle(point, vectors) do |vector|
          vectors << vector
          done(point, vectors)
        end
      end
    end
  end

  def self.is_3d?(point, vectors)
    vectors.count == 3
  end

  def self.rectangle(p0, vectors)
    v1, v2 = vectors
    [p0, p0 + v1, p0 + v1 + v2, p0 + v2]
  end

  def self.done(point, vectors)
    @when_done.call(point, vectors) if @when_done
  end

  def self.using(tool, *params, &block)
    Parametric::Tools.default(tool).as_stage(*params, &block)
  end
end
