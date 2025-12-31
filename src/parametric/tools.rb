require_relative 'geom'
require_relative 'tools/decomposition_tool'
require_relative 'tools/push_pull_tool'
require_relative 'tools/box_tool'
require_relative 'tools/cabinet_tool'


module Parametric

  VK_TAB = 9
  VK_ESCAPE = 27

  module Tools
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

    set_default(:decomposition_tool, DecompositionTool)
    set_default(:push_pull_tool, PushPullTool)
    set_default(:box_tool, BoxTool)
  end
end
