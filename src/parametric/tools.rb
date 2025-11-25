module Parametric::Tools
  def self.default(key)
    default_collection[key]
  end

  def self.set_default(key, tool)
    default_collection[key] = tool
  end

  def self.default_collection
    @default ||= {}
  end
end
