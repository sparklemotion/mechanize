require 'hpricot'
class Hpricot::Elem
  def all_text
    text = ''
    children.each do |child|
      if child.respond_to? :content
        text << child.content
      end
    end
    text
  end
end
