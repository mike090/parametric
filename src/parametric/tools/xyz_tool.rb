require_relative '../lib/geom'

module Parametric::Tools::XYZTool

  def self.as_stage(transformation = IDENTITY, &when_done)
    stage = Object.new
    stage.extend self
    stage.transformation = transformation
    stage.define_singleton_method :done do |view|
      when_done.call(@model.start, @model.vectors) if when_done
      super(view)
    end
    stage.singleton_class.class_eval { private :done }
    stage
  end

  def self.use
    tool = as_stage
    Sketchup.active_model.select_tool tool
    Sketchup.focus
    tool   
  end

  attr_accessor :transformation

  def activate
    @mouse = Sketchup::InputPoint.new
    @model = Model.new(@transformation || IDENTITY)
    update_ui
  end

  def draw(view)
    @mouse.draw(view) if @mouse.display?
    
    case @model.vectors.count
    when 1
      view.draw GL_LINES, @model.start, @model.end
    when 2
      v1, v2 = @model.vectors
      p0 = @model.start
      view.draw GL_LINE_LOOP, [p0, p0 + v1, p0 + v1 + v2, p0 + v2]
    when 3
      v1, v2, v3 = @model.vectors
      p0 = @model.start
      loop = p0, p0 + v1, p0 + v1 + v2, p0 + v2
      view.draw GL_LINE_LOOP, loop
      opposite = loop.map { |point| point + v3 }
      view.draw GL_LINE_LOOP, opposite
      view.draw GL_LINES, loop.zip(opposite).flatten
    end
  end

  def getExtents
    return unless @model.end

    Geom::BoundingBox.new.tap do |bb|
      bb.add @model.start
      bb.add @model.end
    end
  end

  def enableVCB?
    @model.start
  end

  def onCancel(reason, view)
    if @model.start
      @model.start = nil
      view.invalidate
      update_ui
    end
  end

  def onLButtonDown(flags, x, y, view)
    if @model.start
      @model.valid? ? done(view) : view.tooltip = 'invalid position'
    elsif @mouse.valid?
      @model.start = @mouse.position
      update_ui
    end
  end

  def onMouseMove(flags, x, y, view)
    @mouse.pick(view, x, y)
    if @model.start
      @model.end = calculate_end_point
      update_vcb_value
    end
    view.tooltip = @mouse.tooltip
    view.invalidate
  end

  def onUserText(text, view)
    len_vals = text.split(';').map(&:to_l)
    xyz = @model.vectors
    return view.tooltip = 'Incorrect dimensions count' unless
      len_vals.count == xyz.count
    
    xyz.zip(len_vals).map! do |vector, len|
      vector.length = len
      vector
    end
    @model.end = @model.start + xyz.reduce(&:+)

    if @model.vectors.count == 1 
      view.tooltip = 'Corners on the same line'
    else
      done(view)
    end
  rescue ArgumentError
    view.tooltip = 'Invalid length value'
  end

  def resume(view)
    update_ui
    update_vcb_value
  end

  private

  def calculate_end_point
    @model.end = @mouse.position
  end

  def done(view)
    @model = Model.new(@transformation)
    view.invalidate
    update_ui
  end

  def update_ui
    Sketchup.status_text = @model.start ? 'Click to set opposite corner or enter dimensions' : 'Click to set first point'
    Sketchup.vcb_label = 'Dimensions:'
  end

  def update_vcb_value
    Sketchup.vcb_value = @model.vectors.map(&:length).map(&:to_s).join(';')
  end

  class Model
    attr_accessor :start, :end

    def initialize(transformation)
      @transformation = transformation
    end

    def vectors
      xyz = @start.vector_to(@end)
      xyz.transform! @transformation
      Parametric::Geom.decompose_vector(xyz).select(&:valid?).map { |vector| vector.transform @transformation.inverse }
    end

    def valid?
      xyz = vectors
      xyz.count > 1
    end
  end
end
