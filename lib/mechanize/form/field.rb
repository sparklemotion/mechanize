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
  attr_accessor :name, :value, :node, :type

  # This fields value before it's sent through Util.html_unescape.
  attr_reader :raw_value

  # index is used to maintain order for fields with Hash nodes
  attr_accessor :index

  def initialize node, value = node['value']
    @node = node
    @name = Mechanize::Util.html_unescape(node['name'])
    @raw_value = value
    @value = if value.is_a? String
               Mechanize::Util.html_unescape(value)
             else
               value
             end

    @type = node['type']
  end

  def query_value
    [[@name, @value || '']]
  end

  def <=> other
    return 0 if self == other

    # If both are hashes, sort by index
    if Hash === node && Hash === other.node && index
      return index <=> other.index
    end

    # Otherwise put Hash based fields at the end
    return 1 if Hash === node
    return -1 if Hash === other.node

    # Finally let nokogiri determine sort order
    node <=> other.node
  end

  # This method is a shortcut to get field's DOM id.
  # Common usage: form.field_with(:dom_id => "foo")
  def dom_id
    node['id']
  end

  # This method is a shortcut to get field's DOM class.
  # Common usage: form.field_with(:dom_class => "foo")
  def dom_class
    node['class']
  end

  def inspect # :nodoc:
    "[%s:0x%x type: %s name: %s value: %s]" % [
      self.class.name.sub(/Mechanize::Form::/, '').downcase,
      object_id, type, name, value
    ]
  end

end

