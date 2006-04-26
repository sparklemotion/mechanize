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

class Array
  def with
    self
  end

  alias :and :with

  def method_missing(meth_sym, arg)
    if arg.class == Regexp
      find_all { |e| e.send(meth_sym) =~ arg }
    else
      find_all { |e| e.send(meth_sym) == arg }
    end
  end
end

