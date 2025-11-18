require_relative 'staged'
require_relative '..\lib\geom'
require_relative '..\lib\geom\polygon'
require_relative '..\lib\geom\box'

# Include this module if your tool needs to define the box
module Parametric::Tools::BoxDefiner
  
  # after that, your tool will have public methods that 
  # it will redirect to the object returned by the 'define_stage' method
  include Parametric::Tools::Staged

  staged_methods :draw, :onMouseMove, :onLButtonDown, :enableVCB?,
    :resume, :onUserText

  attr_reader :box_model

  def self.use
    tool = Object.new
    tool.extend self
    Sketchup.active_model.select_tool tool
    Sketchup.focus
    tool   
  end

  def activate
    @box_model = Model.new
  end

  def draw(view)
    return super unless @box_model.frozen?

    draw_box(view)
  end

  def getExtents
    ::Geom::BoundingBox.new.tap do |bb|
      bb.add @box_model.first_corner if @box_model.first_corner
      bb.add @box_model.opposite_corner if @box_model.opposite_corner
    end
  end

  def onCancel(reason, view)
    return if @box_model.frozen? || reason != 0
    
    resume(view) if undo
  end

  def enableVCB?
    !@box_model.frozen? && @box_model.first_corner
  end

  private

  def box
    return unless @box_model.frozen?

    vx, vy, vz = @box_model.vectors
    Parametric::Geom::Box.new vx, vy, vz,
      Geom::Transformation.new(@box_model.first_corner)
  end

  def draw_box(view)
    view.draw GL_LINES, box.edges.flatten
  end

  def define_stage
    if @box_model.frozen?

    elsif @box_model.base
      push_pull_stage
    else
      first_stage
    end
  end

  def first_stage
    @first_stage ||= SetBaseStage.new(@box_model)
  end

  def push_pull_stage
    @push_pull_stage ||= PushPullStage.new(@box_model)
  end


  class SetBaseStage

    def initialize(model)
      @model = model
    end

    def activate
      @mouse = Sketchup::InputPoint.new
		  update_ui
    end

    def draw(view)
      @mouse.draw(view) if @mouse.display?
      
      case @model.vectors.count
      when 1
        view.draw GL_LINES, @model.first_corner, @model.opposite_corner
      when 2
        v1, v2 = @model.vectors
        p0 = @model.first_corner
        view.draw GL_LINE_LOOP, p0, p0 + v1, p0 + v1 + v2, p0 + v2
      when 3
        v1, v2, v3 = @model.vectors
        p0 = @model.first_corner
        loop = p0, p0 + v1, p0 + v1 + v2, p0 + v2
        view.draw GL_LINE_LOOP, loop
        opposite = loop.map { |point| point + v3 }
        view.draw GL_LINE_LOOP, opposite
        view.draw GL_LINES, loop.zip(opposite).flatten
      end
    end

    def enableVCB?
      @model.first_corner
    end

    def onLButtonDown(flags, x, y, view)
      if @model.first_corner 
        case @model.vectors.count
        when 2
          @model.base = base
        when 3
          @model.freeze
        end
        view.invalidate
      else
        @model.first_corner = @mouse.position
		    update_ui
      end 
    end

    def onMouseMove(flags, x, y, view)
      @mouse.pick(view, x, y)
      if @model.first_corner
        @model.opposite_corner = calc_opposite_corner
        update_vcb_value
      end
      view.tooltip = @mouse.tooltip
      view.invalidate
    end

    def onUserText(text, view)
      len_values = text.split(';').map(&:to_l)
      diagonal_decomp = @model.vectors
      return view.tooltip = 'Incorrect dimensions count' unless
        len_values.count == diagonal_decomp.count
      
      diagonal_decomp.zip(len_values).map! do |vector, len|
        vector.length = len; vector
      end
      @model.opposite_corner = @model.first_corner + diagonal_decomp.reduce(&:+)
      @model.freeze if @model.valid?
      view.invalidate
    rescue ArgumentError
      view.tooltip = 'Invalid length value'
    end

    def resume(view)
      update_ui
      view.invalidate
    end

    def undo
      return unless @model.first_corner
      
      if @model.base
        @model.opposite_corner = @model.base[2]
        @model.base = nil
      else
        @model.first_corner = @model.opposite_corner = nil
      end
      true
    end

    private

    def calc_opposite_corner
      @mouse.position unless @mouse.position == @model.first_corner
    end

    def base
      return unless @model.first_corner && @model.opposite_corner

      p0 = @model.first_corner
      p2 = @model.opposite_corner
      v1, v2 = @model.vectors
      v2 ||= ::Geom::Vector3d.new

      Parametric::Geom::Polygon.new p0, p0 + v1, p2, p0 + v2
    end

    def update_ui
      if @model.opposite_corner
        Sketchup.status_text = 'Click to set opposite corner or enter dimensions'
      else
        Sketchup.status_text = 
          @model.first_corner ? 'The points do not lie on one of the planes parallel to the projection' :
            'Click to set first corner'
      end
		  Sketchup.vcb_label = 'Dimensions:'
    end

    def update_vcb_value
      Sketchup.vcb_value = @model.vectors.map(&:length).map(&:to_s).join(';')
    end
  end

  class PushPullStage

    def initialize(model)
      @model = model
    end

    def activate
      return if @model.valid? # in the case when the box dimensions were set at the stage of determining the base

      update_ui
      @mouse = Sketchup::InputPoint.new
    end

    def draw(view)
      view.draw(GL_LINE_LOOP, base)
      
      unless base[2] == @model.opposite_corner
        push_pull_vector = base[2].vector_to @model.opposite_corner
        opposite = base.map { |point| point + push_pull_vector }
        view.draw(GL_LINE_LOOP, opposite)
        view.draw(GL_LINES, base.zip(opposite).flatten)
      end
      
      if @mouse.display?
        @mouse.draw(view)
        view.line_stipple = '-'
        view.draw(GL_LINES, @mouse.position, base.center + push_pull_vector)
      end
    end

    def onLButtonDown(flags, x, y, view)
      if @model.valid?
        @model.freeze
        view.invalidate
      end
    end

    def onMouseMove(flags, x, y, view)
      @mouse.pick(view, x, y)
      # capture push pull vector
      push_pull_vector = if @mouse.display? # есть привязка к вершине, плоскости, ребру, направляющей
        p1 = @mouse.position
        p0 = p1.project_to_plane base.plane
        p0.vector_to p1
      else
        pickray = view.pickray(x, y)
        intersection = test_plane.intersect_line(pickray)
        intersection.project_to_plane(base.plane).vector_to(intersection)
      end
      Sketchup.vcb_value = push_pull_vector.length.to_s
      @model.opposite_corner = base[2] + push_pull_vector
      view.tooltip = @mouse.tooltip
      view.invalidate
    end

    def enableVCB?
      true
    end

    def reset
      @test_plane = nil
    end

    def resume(view)
      update_ui
      view.invalidate
    end

    def onUserText(text, view)
      len = text.to_l
      vector = base[2].vector_to(@model.opposite_corner)
      if vector.valid?
        vector.length = len
        @model.opposite_corner = base[2] + vector
        @model.freeze
        view.invalidate
      else
        view.tooltip = 'The direction is uncertain'
      end
    rescue ArgumentError
      view.tooltip = 'Invalid length value'
    end

    private

    def base
      @model.base
    end

    def test_plane
      @test_plane ||= begin
        p0 = base[0]
        p2 = base[2]
        Parametric::Geom::Plane.new p0, p2, p2 + base.plane.normal
      end
    end

    def update_ui
      Sketchup.status_text = 'Click to set box height or enter distance'
      Sketchup.vcb_label = 'Distance:'
    end
  end

  class Model
    attr_accessor :first_corner, :opposite_corner, :base

    def vectors
      calc_vectors || []
    end

    def valid?
      xyz = vectors
      xyz.count == 3 && xyz.all?(&:valid?)
    end
    
    private

    def calc_vectors
      return unless first_corner && opposite_corner

      Parametric::Geom.decompose_vector(first_corner.vector_to opposite_corner).select(&:valid?)
    end
  end
end