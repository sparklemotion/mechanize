require 'mechanize/form/field'
require 'mechanize/form/file_upload'
require 'mechanize/form/button'
require 'mechanize/form/image_button'
require 'mechanize/form/radio_button'
require 'mechanize/form/check_box'
require 'mechanize/form/multi_select_list'
require 'mechanize/form/select_list'
require 'mechanize/form/option'

class Mechanize
  # =Synopsis
  # This class encapsulates a form parsed out of an HTML page.  Each type
  # of input fields available in a form can be accessed through this object.
  # See GlobalForm for more methods.
  #
  # ==Example
  # Find a form and print out its fields
  #  form = page.forms.first # => Mechanize::Form
  #  form.fields.each { |f| puts f.name }
  # Set the input field 'name' to "Aaron"
  #  form['name'] = 'Aaron'
  #  puts form['name']
  class Form
    attr_accessor :method, :action, :name

    attr_reader :fields, :buttons, :file_uploads, :radiobuttons, :checkboxes
    attr_accessor :enctype

    alias :elements :fields

    attr_reader :form_node
    attr_reader :page

    def initialize(node, mech=nil, page=nil)
      @enctype = node['enctype'] || 'application/x-www-form-urlencoded'
      @form_node        = node
      @action           = Util.html_unescape(node['action'])
      @method           = (node['method'] || 'GET').upcase
      @name             = node['name']
      @clicked_buttons  = []
      @page             = page
      @mech             = mech

      parse
    end

    # Returns whether or not the form contains a field with +field_name+
    def has_field?(field_name)
      ! fields.find { |f| f.name.eql? field_name }.nil?
    end

    alias :has_key? :has_field?

    def has_value?(value)
      ! fields.find { |f| f.value.eql? value }.nil?
    end

    def keys; fields.map { |f| f.name }; end

    def values; fields.map { |f| f.value }; end

    def submits  ; @submits   ||= buttons.select { |f| f.class == Submit   }; end
    def resets   ; @resets    ||= buttons.select { |f| f.class == Reset    }; end
    def texts    ; @texts     ||=  fields.select { |f| f.class == Text     }; end
    def hiddens  ; @hiddens   ||=  fields.select { |f| f.class == Hidden   }; end
    def textareas; @textareas ||=  fields.select { |f| f.class == Textarea }; end

    def submit_button?(button_name) !!  submits.find{|f| f.name == button_name}; end
    def reset_button?(button_name)  !!   resets.find{|f| f.name == button_name}; end
    def text_field?(field_name)     !!    texts.find{|f| f.name == field_name}; end
    def hidden_field?(field_name)   !!  hiddens.find{|f| f.name == field_name}; end
    def textarea_field?(field_name) !!textareas.find{|f| f.name == field_name}; end
      
    # This method is a shortcut to get form's DOM id.
    # Common usage: page.form_with(:dom_id => "foorm")
    def dom_id
      form_node['id']  
    end

    # Add a field with +field_name+ and +value+
    def add_field!(field_name, value = nil)
      fields << Field.new({'name' => field_name}, value)
    end

    # This method sets multiple fields on the form.  It takes a list of field
    # name, value pairs.  If there is more than one field found with the
    # same name, this method will set the first one found.  If you want to
    # set the value of a duplicate field, use a value which is a Hash with
    # the key as the index in to the form.  The index
    # is zero based.  For example, to set the second field named 'foo', you
    # could do the following:
    #  form.set_fields( :foo => { 1 => 'bar' } )
    def set_fields(fields = {})
      fields.each do |k,v|
        case v
        when Hash
          v.each do |index, value|
            self.fields_with(:name => k.to_s).[](index).value = value
          end
        else
          value = nil
          index = 0
          [v].flatten.each do |val|
            index = val.to_i unless value.nil?
            value = val if value.nil?
          end
          self.fields_with(:name => k.to_s).[](index).value = value
        end
      end
    end

    # Fetch the value of the first input field with the name passed in
    # ==Example
    # Fetch the value set in the input field 'name'
    #  puts form['name']
    def [](field_name)
      f = field(field_name)
      f && f.value
    end

    # Set the value of the first input field with the name passed in
    # ==Example
    # Set the value in the input field 'name' to "Aaron"
    #  form['name'] = 'Aaron'
    def []=(field_name, value)
      f = field(field_name)
      if f.nil?
        add_field!(field_name, value)
      else
        f.value = value
      end
    end

    # Treat form fields like accessors.
    def method_missing(id,*args)
      method = id.to_s.gsub(/=$/, '')
      if field(method)
        return field(method).value if args.empty?
        return field(method).value = args[0]
      end
      super
    end

    # Submit this form with the button passed in
    def submit button=nil, headers = {}
      @mech.submit(self, button, headers)
    end

    # Submit form using +button+. Defaults
    # to the first button.
    def click_button(button = buttons.first)
      submit(button)
    end

    # This method is sub-method of build_query.
    # It converts charset of query value of fields into expected one.
    def proc_query(field)
      return unless field.query_value
      field.query_value.map{|(name, val)|
        [from_native_charset(name), from_native_charset(val.to_s)]
      }
    end
    private :proc_query

    def from_native_charset str
      Util.from_native_charset(str,page && page.encoding)
    end
    private :from_native_charset

    # This method builds an array of arrays that represent the query
    # parameters to be used with this form.  The return value can then
    # be used to create a query string for this form.
    def build_query(buttons = [])
      query = []

      (fields + checkboxes).sort.each do |f|
        case f
        when Form::CheckBox
          if f.checked
            qval = proc_query(f)
            query.push(*qval)
          end
        when Form::Field
          qval = proc_query(f)
          query.push(*qval)
        end
      end

      radio_groups = {}
      radiobuttons.each do |f|
        fname = from_native_charset(f.name)
        radio_groups[fname] ||= []
        radio_groups[fname] << f
      end

      # take one radio button from each group
      radio_groups.each_value do |g|
        checked = g.select {|f| f.checked}

        if checked.size == 1
          f = checked.first
          qval = proc_query(f)
          query.push(*qval)
        elsif checked.size > 1
          raise "multiple radiobuttons are checked in the same group!"
        end
      end

      @clicked_buttons.each { |b|
        qval = proc_query(b)
        query.push(*qval)
      }
      query
    end

    # This method adds a button to the query.  If the form needs to be
    # submitted with multiple buttons, pass each button to this method.
    def add_button_to_query(button)
      @clicked_buttons << button
    end

    # This method calculates the request data to be sent back to the server
    # for this form, depending on if this is a regular post, get, or a
    # multi-part post,
    def request_data
      query_params = build_query()
      case @enctype.downcase
      when /^multipart\/form-data/
        boundary = rand_string(20)
        @enctype = "multipart/form-data; boundary=#{boundary}"
        params = []
        query_params.each { |k,v| params << param_to_multipart(k, v) unless k.nil? }
        @file_uploads.each { |f| params << file_to_multipart(f) }
        params.collect { |p| "--#{boundary}\r\n#{p.respond_to?(:force_encoding) ? p.force_encoding('ASCII-8BIT') : p}" }.join('') +
          "--#{boundary}--\r\n"
      else
        Mechanize::Util.build_query_string(query_params)
      end
    end

    # Removes all fields with name +field_name+.
    def delete_field!(field_name)
      @fields.delete_if{ |f| f.name == field_name}
    end

    ##
    # :method: field_with(criteria)
    #
    # Find one field that matches +criteria+
    # Example:
    #   form.field_with(:dom_id => "exact_field_id").value = 'hello'
    #   form.field_with(:id => "exact_field_id").value = 'hello' # :id works too!

    ##
    # :method: fields_with(criteria)
    #
    # Find all fields that match +criteria+
    # Example:
    #   form.fields_with(:value => /foo/).each do |field|
    #     field.value = 'hello!'
    #   end

    ##
    # :method: button_with(criteria)
    #
    # Find one button that matches +criteria+
    # Example:
    #   form.button_with(:value => /submit/).value = 'hello'

    ##
    # :method: buttons_with(criteria)
    #
    # Find all buttons that match +criteria+
    # Example:
    #   form.buttons_with(:value => /submit/).each do |button|
    #     button.value = 'hello!'
    #   end

    ##
    # :method: file_upload_with(criteria)
    #
    # Find one file upload field that matches +criteria+
    # Example:
    #   form.file_upload_with(:file_name => /picture/).value = 'foo'

    ##
    # :method: file_uploads_with(criteria)
    #
    # Find all file upload fields that match +criteria+
    # Example:
    #   form.file_uploads_with(:file_name => /picutre/).each do |field|
    #     field.value = 'foo!'
    #   end

    ##
    # :method: radiobutton_with(criteria)
    #
    # Find one radio button that matches +criteria+
    # Example:
    #   form.radiobutton_with(:name => /woo/).check

    ##
    # :method: radiobuttons_with(criteria)
    #
    # Find all radio buttons that match +criteria+
    # Example:
    #   form.radiobuttons_with(:name => /woo/).each do |field|
    #     field.check
    #   end

    ##
    # :method: checkbox_with(criteria)
    #
    # Find one checkbox that matches +criteria+
    # Example:
    #   form.checkbox_with(:name => /woo/).check

    ##
    # :method: checkboxes_with(criteria)
    #
    # Find all checkboxes that match +criteria+
    # Example:
    #   form.checkboxes_with(:name => /woo/).each do |field|
    #     field.check
    #   end

    # Woo! meta programming time
    { :field        => :fields,
      :button       => :buttons,
      :file_upload  => :file_uploads,
      :radiobutton  => :radiobuttons,
      :checkbox     => :checkboxes,
    }.each do |singular,plural|
      eval(<<-eomethod)
          def #{plural}_with criteria = {}
            criteria = {:name => criteria} if String === criteria
            f = #{plural}.find_all do |thing|
              # criteria.all? { |k,v| v === thing.send(k) }
              criteria.all? do |k,v| 
                k = :dom_id if(k.to_s == "id")
                v === thing.send(k)
              end
            end
            yield f if block_given?
            f
          end

          def #{singular}_with criteria = {}
            f = #{plural}_with(criteria).first
            yield f if block_given?
            f
          end
          alias :#{singular} :#{singular}_with
        eomethod
    end

    private
    def parse
      @fields       = []
      @buttons      = []
      @file_uploads = []
      @radiobuttons = []
      @checkboxes   = []

      # Find all input tags
      form_node.search('input').each do |node|
        type = (node['type'] || 'text').downcase
        name = node['name']
        next if name.nil? && !(type == 'submit' || type =='button' || type == 'image')
        case type
        when 'radio'
          @radiobuttons << RadioButton.new(node, self)
        when 'checkbox'
          @checkboxes << CheckBox.new(node, self)
        when 'file'
          @file_uploads << FileUpload.new(node, nil)
        when 'submit'
          @buttons << Submit.new(node)
        when 'button'
          @buttons << Button.new(node)
        when 'reset'
          @buttons << Reset.new(node)
        when 'image'
          @buttons << ImageButton.new(node)
        when 'hidden'
          @fields << Hidden.new(node, node['value'] || '')
        when 'text'
          @fields << Text.new(node, node['value'] || '')
        when 'textarea'
          @fields << Textarea.new(node, node['value'] || '')
        else
          @fields << Field.new(node, node['value'] || '')
        end
      end

      # Find all textarea tags
      form_node.search('textarea').each do |node|
        next if node['name'].nil?
        @fields << Field.new(node, node.inner_text)
      end

      # Find all select tags
      form_node.search('select').each do |node|
        next if node['name'].nil?
        if node.has_attribute? 'multiple'
          @fields << MultiSelectList.new(node)
        else
          @fields << SelectList.new(node)
        end
      end

      # Find all submit button tags
      # FIXME: what can I do with the reset buttons?
      form_node.search('button').each do |node|
        type = (node['type'] || 'submit').downcase
        next if type == 'reset'
        @buttons << Button.new(node)
      end
    end

    def rand_string(len = 10)
      chars = ("a".."z").to_a + ("A".."Z").to_a
      string = ""
      1.upto(len) { |i| string << chars[rand(chars.size-1)] }
      string
    end

    def mime_value_quote(str)
      str.gsub(/(["\r\\])/){|s| '\\' + s}
    end

    def param_to_multipart(name, value)
      return "Content-Disposition: form-data; name=\"" +
        "#{mime_value_quote(name)}\"\r\n" +
        "\r\n#{value}\r\n"
    end

    def file_to_multipart(file)
      file_name = file.file_name ? ::File.basename(file.file_name) : ''
      body =  "Content-Disposition: form-data; name=\"" +
        "#{mime_value_quote(file.name)}\"; " +
        "filename=\"#{mime_value_quote(file_name)}\"\r\n" +
        "Content-Transfer-Encoding: binary\r\n"

      if file.file_data.nil? and ! file.file_name.nil?
        file.file_data = ::File.open(file.file_name, "rb") { |f| f.read }
        file.mime_type = WEBrick::HTTPUtils.mime_type(file.file_name,
                                                      WEBrick::HTTPUtils::DefaultMimeTypes)
      end

      if file.mime_type != nil
        body << "Content-Type: #{file.mime_type}\r\n"
      end

      body <<
        if file.file_data.respond_to? :read
          "\r\n#{file.file_data.read}\r\n"
        else
          "\r\n#{file.file_data}\r\n"
        end

      body
    end
  end
end
