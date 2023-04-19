class BaseAPI
  def self.attr_defs = @attr_defs ||= []
end

module CommonAttrs
  def self.attr_defs = @attr_defs ||= []
end

class ProjectAPI < BaseAPI
include CommonAttrs
def self.get_attr_defs = self.attr_defs + CommonAttrs.attr_defs
end

class OtherAPI < BaseAPI
include CommonAttrs
def self.get_attr_defs = self.attr_defs + CommonAttrs.attr_defs
end

class TopLevelAPI < BaseAPI
  def self.get_attr_defs = self.attr_defs

end

ProjectAPI.attr_defs << :a
CommonAttrs.attr_defs << :b
OtherAPI.attr_defs << :c
TopLevelAPI.attr_defs << :d

puts ProjectAPI.get_attr_defs
puts "--"
#puts CommonAttrs.get_attr_defs
#puts "--"
puts OtherAPI.get_attr_defs
puts "--"
puts TopLevelAPI.get_attr_defs

puts ProjectAPI.ancestors
puts ProjectAPI.superclass