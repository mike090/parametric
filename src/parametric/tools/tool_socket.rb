class Parametric::Tools::ToolSocket

  def activate
    @activated = true
    try @tool, :activate
  end

  def deactivate(view)
    @activated = false
    try @tool, :deactivate, view
    reset
  end

  def select_tool(tool)
    try @tool, :deactivate, Sketchup.active_model.active_view
    try tool, :activate if @activated
    @tool = tool
  end

  def respond_to?(symbol, include_all=false)
    super || @tool&.respond_to?(symbol)
  end

  def method_missing(symbol, *args)
    try @tool, symbol, *args
  end

  def reset
    @tool = nil
  end

  private

  def try(receiver, method, *args)
    receiver&.public_send(method, *args) if receiver.respond_to? method
  end
end
