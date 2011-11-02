##
# This class represents a field in a form.  It handles the following input
# tags found in a form:
#
# * text
# * password
# * hidden
# * int
# * textarea
# * keygen
#
# To set the value of a field, just use the value method:
#
#   field.value = "foo"

class Mechanize::Form::Field
  attr_accessor :name, :value, :node

  def initialize node, value = node['value']
    @node = node
    @name = Mechanize::Util.html_unescape(node['name'])
    @value = if value.is_a? String
               Mechanize::Util.html_unescape(value)
             else
               value
             end
  end

  def query_value
    [[@name, @value || '']]
  end

  def <=> other
    return 0 if self == other
    return 1 if Hash === node
    return -1 if Hash === other.node
    node <=> other.node
  end

  # This method is a shortcut to get field's DOM id.
  # Common usage: form.field_with(:dom_id => "foo")
  def dom_id
    node['id']
  end

  # This method is a shortcut to get field's DOM id.
  # Common usage: form.field_with(:dom_class => "foo")
  def dom_class
    node['class']
  end
end

