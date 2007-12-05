require 'web/htmltools/xmltree'
require 'mechanize/rexml'

class WWW::Mechanize::REXMLPage < WWW::Mechanize::Page
  def initialize(uri=nil, response=nil, body=nil, code=nil, mech=nil)
    @body           = body
    @watch_for_set  = {}
    @mech           = mech

    # construct parser and feed with HTML
    parser = HTMLTree::XMLParser.new
    begin
      parser.feed(@body)
    rescue => ex
      if ex.message =~ /attempted adding second root element to document/ and
        # Put the whole document inside a single root element, which I
        # simply name <root>, just to make the parser happy. It's no
        #longer valid HTML, but without a single root element, it's not
        # valid HTML as well.

        # TODO: leave a possible doctype definition outside this element.
        parser = HTMLTree::XMLParser.new
        parser.feed("<root>" + @body + "</root>")
      else
        raise
      end
    end

    @root = parser.document

    yield self if block_given?

    super(uri, response, body, code)
  end
end
