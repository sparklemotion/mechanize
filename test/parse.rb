require 'rubygems'

require 'web/htmltools/xmltree'

parser = HTMLTree::XMLParser.new
parser.feed(DATA.read.chomp)
root = parser.document

root.each_recursive { |node|
  name = node.name.downcase
  case name
  when 'form'
    node.each_recursive { |n|
      puts n.name.downcase
    }
  end
}

__END__
<html>
<body>
  <table>
    <tr>
      <td>
        <form name="foo">
        <table>
          <tr><td><h1>Header</h1></td></tr>
          <tr>
            <td>
              <input type="text" name="hey" value="" />
            </td>
          </tr>
        </table>
        </form>
      </td>
    </tr>
  </table>
</body>
</html>
