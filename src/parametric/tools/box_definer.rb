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
    tool = as_stage
    Sketchup.active_model.select_tool tool
    Sketchup.focus
    tool   
  end

  def self.as_stage(&when_done)
    stage = Object.new
    stage.extend self
    stage.define_singleton_method :fix_box do
      super()
      when_done.call(@box_params) if when_done
    end
    stage.singleton_class.class_eval { private :fix_box }
    stage
  end

  def activate
    reset
  end

  def box_defined?
    @box_params
  end

  def draw(view)
    return super unless box_defined?

    draw_box(view)
  end

  def getExtents
    ::Geom::BoundingBox.new.tap do |bb|
      bb.add @box_model.first_corner if @box_model.first_corner
      bb.add @box_model.opposite_corner if @box_model.opposite_corner
    end
  end

  def onCancel(reason, view)
    return unless reason == 0
    
    resume(view) if undo
  end

  def enableVCB?
    return if box_defined?
    
    @box_model.first_corner
  end

  private

  def box
    return unless box_defined?

    params = @box_params[1..] << Geom::Transformation.new(@box_params.first)
    Parametric::Geom::Box.new *params
  end

  def draw_box(view)
    view.draw GL_LINES, box.edges.flatten
  end

  def fix_box
    @box_params = [@box_model.first_corner] + @box_model.vectors
    next_stage nil # prevent model changes through user input events
    Sketchup.status_text = ''
    Sketchup.vcb_label = ''
  end

  def undo
    @box_params = nil
    super
  end

  def first_stage
    @first_stage ||= SetBaseStage.new(@box_model) do
       @box_model.valid? ? fix_box : next_stage(push_pull_stage)
    end
  end

  def push_pull_stage
    @push_pull_stage ||= PushPullStage.new(@box_model) do
      fix_box
    end
  end

  def reset
    @box_model = Model.new
    @first_stage = @push_pull_stage = nil
    stages.clear
    next_stage(first_stage)
  end

  class SetBaseStage

    def initialize(model, &when_done)
      @model = model
      @when_done = when_done
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

    def onLButtonDown(flags, x, y, view)
      if @model.first_corner 
        if @model.vectors.count == 1 
          view.tooltip = 'Corners on the same line'
        else
          done
          view.invalidate
        end
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
        vector.length = len
        vector
      end
      @model.opposite_corner = @model.first_corner + diagonal_decomp.reduce(&:+)

      if @model.vectors.count == 1 
        view.tooltip = 'Corners on the same line'
      else
        done
        view.invalidate
      end
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

    def done
      @model.base = base if @model.vectors.count == 2
      @when_done.call(self, @model) if @when_done
    end

    def calc_opposite_corner
      @mouse.position unless @mouse.position == @model.first_corner
    end

    def base
      v1, v2 = @model.vectors
      return unless v2

      p0 = @model.first_corner
      p2 = @model.opposite_corner

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

    def initialize(model, &when_done)
      @model = model
      @when_done = when_done
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
        done
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

    def reset
      @test_plane = nil
    end

    def resume(view)
      update_ui
      view.invalidate
    end

    def onUserText(text, view)
      len = text.to_l
      return view.tooltip = 'Zero length' if len == 0

      vector = base[2].vector_to(@model.opposite_corner)
      if vector.valid?
        vector.length = len
        @model.opposite_corner = base[2] + vector
        done
        view.invalidate
      else
        view.tooltip = 'The direction is uncertain'
      end
    rescue ArgumentError
      view.tooltip = 'Invalid length value'
    end

    def undo
      return unless @model.base && @model.valid?

      @model.opposite_corner = @model.base[2]
    end

    private

    def done
      @when_done.call(self, @model) if @when_done
    end

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