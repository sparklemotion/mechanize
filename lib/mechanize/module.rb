class Module
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

