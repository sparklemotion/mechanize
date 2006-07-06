#
# Copyright (c) 2005 by Michael Neumann (mneumann@ntecs.de).
# Released under the same terms of license as Ruby.
#

require 'rexml/rexml'

class REXML::Text
  def collect_text_recursively
    value()
  end
end

class REXML::Comment
  def collect_text_recursively
    []
  end
end

module REXML::Node

# Aliasing functions to get rid of warnings.  Remove when support for 1.8.2
# is dropped.
if RUBY_VERSION > "1.8.2"
  alias :old_each_recursive       :each_recursive
  alias :old_find_first_recursive :find_first_recursive
  alias :old_index_in_parent      :index_in_parent
end

  # Visit all subnodes of +self+ recursively

  def each_recursive(&block) # :yields: node
    self.elements.each {|node|
      block.call(node)
      node.each_recursive(&block) 
    }
  end

  # Find (and return) first subnode (recursively) for which the block evaluates
  # to true. Returns +nil+ if none was found.

  def find_first_recursive(&block) # :yields: node
    each_recursive {|node|
      return node if block.call(node)
    }
    return nil
  end

  # Find all subnodes (recursively) for which the block evaluates to true. 

  def find_all_recursive(&block) # :yields: node
    arr = []
    each_recursive {|node|
      arr << node if block.call(node)
    }
    arr
  end

  # Returns the index that +self+ has in its parent's elements array, so that
  # the following equation holds true:
  #
  #   node == node.parent.elements[node.index_in_parent]

  def index_in_parent
    parent.index(self)+1
  end

  # Recursivly collects all text strings starting into an array.
  #
  # E.g. the method would return [["abc"], "def"] for this node:
  # 
  #   <i><b>abc</b>def</i>
  
  def collect_text_recursively
    map {|n| n.collect_text_recursively}
  end

  # Returns all text of all subnodes (recursivly), merged into one string.
  # This is equivalent to:
  #
  #   collect_text_recursively.flatten.join("")

  def all_text
    collect_text_recursively.flatten.join("")
  end

end

#
# Starting with +root_node+, we recursively look for a node with the given
# +tag+, the given +attributes+ (a Hash) and whoose text equals or matches the
# +text+ string or regular expression. 
#
# To find the following node:
#
#   <td class='abc'>text</td>
#
# We use:
#
#   find_node(root, 'td', {'class' => 'abc'}, "text")
#
# Returns +nil+ if no matching node was found. 

def find_node(root_node, tag, attributes, text=nil)
  root_node.find_first_recursive {|node|
    node.name == tag and
    attributes.all? {|attr, val| node.attributes[attr] == val} and
    (text ? text === node.text : true)
  }
end

#
# Extract specific columns (specified by the position of it's corrensponding
# header column) from a table. 
#
# Given the following table:
#
#   <table>
#     <tr>
#       <td>A</td>
#       <td>B</td>
#       <td>C</td>
#     </tr>
#     <tr>
#       <td>A.1</td>
#       <td>B.1</td>
#       <td>C.1</td>
#     </tr>
#     <tr>
#       <td>A.2</td>
#       <td>B.2</td>
#       <td>C.2</td>
#     </tr>
#   </table>
#
# To extract the first (A) and last (C) column:
#
#   extract_from_table(root_node, ["A", "C"])  
#
# And you get this as result:
#
#   [ 
#     ["A.1", "C.1"],
#     ["A.2", "C.2"]
#   ]
#

def extract_from_table(root_node, headers, header_tags = %w(td th))

  # extract and collect all header nodes

  header_nodes = headers.collect { |header| 
    root_node.find_first_recursive {|node| 
      header_tags.include?(node.name.downcase) and header === node.all_text
    }
  }

  raise "some headers not found" if header_nodes.compact.size < headers.size

  # assert that all headers have the same parent 'header_row', which is the row
  # in which the header_nodes are contained. 'table' is the surrounding table tag.

  header_row = header_nodes.first.parent
  table = header_row.parent 

  raise "different parents" unless header_nodes.all? {|n| n.parent == header_row}

  # we now iterate over all rows in the table that follows the header_row. 
  # for each row we collect the elements at the same positions as the header_nodes.
  # this is what we finally return from the method. 

  (header_row.index_in_parent .. table.elements.size).collect do |inx|
    row = table.elements[inx]
    header_nodes.collect { |n| row.elements[ n.parent.elements.index(n) ].text }
  end 
end

# Given a HTML table, this method returns a matrix (2-dim array), with all the
# table-data elements correctly placed in it. 
#
# If there's a table data element which uses 'colspan', that node is stored in
# at the current position of the row followed by (colspan-1) nil values.
#
# Example:
#
#   <table>
#     <tr>
#       <td>A</td>
#       <td>B</td>
#     </tr>
#     <tr>
#       <td colspan="2">C</td>
#     </tr>
#   </table>
#
# Result:
#
#   [
#     [A, B],
#     [C, nil]
#   ]
#
# where A, B and C are the corresponding "<td>" nodes.
#

def table_to_matrix(table_node)
  matrix = []

  # for each row
  table_node.elements.each('tr') {|r|
    row = []
    r.elements.each {|data|
      next unless ['td', 'th'].include?(data.name)
      row << data

      # fill with empty elements
      colspan = (data.attributes['colspan'] || 1).to_i
      (colspan - 1).times { row << nil }
    }
    matrix << row
  }

  return matrix
end
