require_relative '..\staged'
require_relative '..\..\lib\geom'
require_relative '..\..\lib\geom\polygon'

module BoxDefiner
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
    @mouse = Sketchup::InputPoint.new
    @box_model = Model.new
    update_prompt
  end

  def draw(view)
  #   super
    # puts "#{self.class}\##{__method__}"
    return super unless push_pull_stage.box_defined?

    draw_box(view)
  #   return unless @mouse.valid?

  #   view.tooltip = @mouse.tooltip
  #   @mouse.draw(view) if @mouse.display?
  end

  def getExtents
    ::Geom::BoundingBox.new.tap do |bb|
      bb.add @box_model.first_corner if @box_model.first_corner
      bb.add @box_model.opposite_corner if @box_model.opposite_corner
    end
  end

  def onMouseMove(flags, x, y, view)
    super
    @mouse.pick(view, x, y)
    update_vcb_value
  end

  def onKeyDown(key, repeat, flags, view)
    case key
    when  27 # KEY_ESCAPE
      if stage = undo
        # stage.set_mouse @mouse
			  resume view
      end 
    else
      super
    end
  end

  def onUserText(text, view)
    len_values = text.split(';').map(&:to_l)
    box_diagonal = @box_model.vectors
    super unless len_values.count == box_diagonal.count
    box_diagonal.zip(len_values).map! { |vector, len| vector.length = len; vector }
    @box_model.opposite_corner = @box_model.first_corner + box_diagonal.reduce(&:+)
    view.invalidate
	rescue ArgumentError
		view.tooltip = 'Invalid length value'
  end

  def enableVCB?
    (@box_model.vectors.count == 3) || super
  end

  # private

  def draw_box(view)
    p0 = @box_model.first_corner
    v1, v2, v3 = @box_model.vectors
    base = [p0, p0 + v1, p0 + v1 + v2, p0 +v2]
    view.draw GL_LINE_LOOP, base
    opposite = base.map { |point| point + v3 }
    view.draw GL_LINE_LOOP, opposite
    view.draw GL_LINES, base.zip(opposite).flatten
  end

  def define_stage
    # puts "#{self.class}\##{__method__}" if $debug
    return first_stage unless first_stage.base_defined?

    return push_pull_stage unless push_pull_stage.box_defined?
  end

  def first_stage
    @first_stage ||= SetBaseStage.new(@box_model)
  end

  def push_pull_stage
    @push_pull_stage ||= PushPullStage.new(@box_model)
  end

  def update_vcb_value
    Sketchup.vcb_value = @box_model.vectors.map(&:length).map(&:to_s).join(';')
  end


  class SetBaseStage

    def initialize(model)
      @model = model
    end

    def activate
      @done_flag = false
      @mouse = Sketchup::InputPoint.new
      Sketchup.status_text = 'Click to pick first box corner'
    end

    def base_defined?
      @done_flag
    end

    def draw(view)
      @mouse.draw(view) if @mouse.display?
      loop = base
      view.draw(GL_LINE_LOOP, loop) if loop
    end

    def enableVCB?
      true
    end

    def onMouseMove(flags, x, y, view)
      @mouse.pick(view, x, y)
      @model.opposite_corner = calc_opposite_corner if @model.first_corner
      view.tooltip = @mouse.tooltip
		  update_ui
      view.invalidate
    end

    def onLButtonDown(flags, x, y, view)
      if @model.first_corner
        @done_flag = !!@model.opposite_corner
      else
        @model.first_corner = @mouse.position
        Sketchup.status_text = 'Click to set opposite corner or enter dimensions'
      end 
    end

    def onUserText(text, view)
      
    end

    def reset
      @done_flag = false
    end

    def resume(view)
      update_ui
      view.invalidate
    end

    def undo
      puts "#{self.class}\##{__method__}" if $debug
      return unless @model.first_corner
      
      if @done_flag
        @done_flag = false
      else
        return unless @model.first_corner

        @model.first_corner = @model.opposite_corner = nil
      end
      true
    end

    # private

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
  end

  class PushPullStage

    def initialize(model)
      @model = model
    end

    def activate
      puts "#{self.class}\##{__method__}" if $debug
      return @done_flag = true if @model.valid? # in the case when the box dimensions were set at the stage of determining the base

      @done_flag = false
      @mouse = Sketchup::InputPoint.new
      base
    end

    def box_defined?
      @done_flag
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
      return if @done_flag

      if @model.vectors.count == 3
        @done_flag = true 
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
      @model.opposite_corner = @base[2] + push_pull_vector
      view.tooltip = @mouse.tooltip
      view.invalidate
    end

    def enableVCB?
      true
    end

    def reset
      @done_flag = false
      @base = nil
      @test_plane = nil
    end

    def resume(view)
      update_ui
      view.invalidate
    end

    def undo
      puts "#{self.class}\##{__method__}" if $debug
      return unless @base # in the case when the box dimensions were set at the stage of determining the base
      
      if @done_flag
        @done_flag = false
        true
      else
        @model.opposite_corner = @base[2]
        @base = nil
        @test_plane = nil
      end
    end

    private

    def base
      @base ||= begin
        p0 = @model.first_corner
        v1,v2 = @model.vectors
        Parametric::Geom::Polygon.new(p0, p0 + v1, p0 + v1 + v2, p0 + v2)
      end
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
    attr_accessor :first_corner, :opposite_corner

    def vectors
      calc_vectors || []
    end

    def valid?
      vectors.count == 3
    end
    
    private

    def calc_vectors
      return unless first_corner && opposite_corner

      Parametric::Geom.decompose_vector(first_corner.vector_to opposite_corner).select(&:valid?)
    end
  end
end