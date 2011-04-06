  # This class represents a select list or drop down box in a Form.  Set the
  # value for the list by calling SelectList#value=.  SelectList contains a
  # list of Option that were found.  After finding the correct option, set
  # the select lists value to the option value:
  #  selectlist.value = selectlist.options.first.value
  # Options can also be selected by "clicking" or selecting them.  See Option
class Mechanize::Form::SelectList < Mechanize::Form::MultiSelectList
  def initialize node
    super
    if selected_options.length > 1
      selected_options.reverse[1..selected_options.length].each do |o|
        o.unselect
      end
    end
  end

  ##
  # Find all options on this select list with +criteria+
  # Example:
  #   select_list.options_with(:value => /1|2/).each do |field|
  #     field.value = '20'
  #   end
  def options_with criteria
    criteria = {:name => criteria} if String === criteria
    f = @options.find_all do |thing|
      criteria.all? { |k,v| v === thing.send(k) }
    end
    yield f if block_given?
    f
  end

  ##
  # Find one option on this select list with +criteria+
  # Example:
  #   select_list.option_with(:value => '1').value = 'foo'
  def option_with criteria
    f = options_with(criteria).first
      yield f if block_given?
    f
  end

  def value
    value = super
    if value.length > 0
      value.last
    elsif @options.length > 0
      @options.first.value
    else
      nil
    end
  end

  def value=(new)
    if new != new.to_s and new.respond_to? :first
      super([new.first])
    else
      super([new.to_s])
    end
  end

  def query_value
    value ? [[name, value]] : nil
  end
end

