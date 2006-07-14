require 'hpricot'

class Module # :nodoc:
  def attr_finder(*syms)
    syms.each do |sym|
      class_eval %{ def #{sym.to_s}(hash = nil)
                      if hash == nil
                        @#{sym.to_s}
                      else
                        @#{sym.to_s}.find_all do |t|
                          found = true
                          hash.each_key \{ |key|
                            found = false if t.send(key.to_sym) != hash[key]
                          \}
                          found
                        end
                      end
                    end
                  }
    end
  end
end

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
