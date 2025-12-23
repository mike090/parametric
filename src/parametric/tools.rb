require_relative 'tools/xyz_tool'
require_relative 'tools/push_pull_tool'
require_relative 'tools/box_tool'
require_relative 'tools/module_tool'

VK_TAB = 9
VK_ESCAPE = 27

module Parametric::Tools
  def self.default(key)
    default_collection[key]
  end

  def self.set_default(key, tool)
    removable = default(key)
    default_collection[key] = tool
    removable
  end

  def self.default_collection
    @default ||= {}
  end

  set_default(:xyz_tool, XYZTool)
  set_default(:push_pull_tool, PushPullTool)
  set_default(:box_tool, BoxTool)
end
