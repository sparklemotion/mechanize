$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rexml/document'
require 'mechanize/parsing'

class TestParsing < Test::Unit::TestCase
  def test_collect_text_recursively
    assert_equal [["abc"], "def"], root_for("<i><b>abc</b>def</i>").collect_text_recursively

    assert_equal ["asdf", ["abc"], "def"], root_for("<i>asdf<b>abc</b>def</i>").collect_text_recursively
  end

  def test_index_in_parent
    table = root_for %(<table><tr><td>A</td><td>B</td></tr><tr><td colspan="2">C</td></tr></table>)
    node = table.find_first_recursive {|n| n.name == 'tr'}
    assert_equal node, node.parent.elements[node.index_in_parent]
  end

  def test_table_to_matrix
    table = root_for %(<table><tr><td>A</td><td>B</td></tr><tr><td colspan="2">C</td></tr></table>)
    matrix = table_to_matrix(table)
    assert_equal "A", matrix[0][0].all_text
    assert_equal "B", matrix[0][1].all_text
    assert_equal "C", matrix[1][0].all_text
    assert_equal nil, matrix[1][1]
  end

  def test_extract_from_table
    table = root_for %(
      <table>
        <tr>
          <td>A</td>
          <td>B</td>
          <td>C</td>
        </tr>
        <tr>
          <td>A.1</td>
          <td>B.1</td>
          <td>C.1</td>
        </tr>
        <tr>
          <td>A.2</td>
          <td>B.2</td>
          <td>C.2</td>
        </tr>
      </table>)

    assert_equal [ ["A.1", "C.1"], ["A.2", "C.2"] ], extract_from_table(table, ["A", "C"])
  end

  private

  def root_for(str)
    REXML::Document.new(str).root
  end
=begin
  def document_for(str)
    parser = HTMLTree::XMLParser.new
    parser.feed(str)
    parser.document
  end
=end
end
