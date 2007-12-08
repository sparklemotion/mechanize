require 'www/mechanize/form/field'
require 'www/mechanize/form/file_upload'
require 'www/mechanize/form/button'
require 'www/mechanize/form/image_button'
require 'www/mechanize/form/radio_button'
require 'www/mechanize/form/check_box'
require 'www/mechanize/form/multi_select_list'
require 'www/mechanize/form/select_list'
require 'www/mechanize/form/option'

module WWW
  class Mechanize
    # =Synopsis
    # This class encapsulates a form parsed out of an HTML page.  Each type
    # of input fields available in a form can be accessed through this object.
    # See GlobalForm for more methods.
    #
    # ==Example
    # Find a form and print out its fields
    #  form = page.forms.first # => WWW::Mechanize::Form
    #  form.fields.each { |f| puts f.name }
    # Set the input field 'name' to "Aaron"
    #  form['name'] = 'Aaron'
    #  puts form['name']
    class Form
      attr_accessor :method, :action, :name
    
      attr_reader :fields, :buttons, :file_uploads, :radiobuttons, :checkboxes
      attr_reader :enctype

      alias :elements :fields
    
      attr_reader :form_node
      attr_reader :page
    
      def initialize(node, mech=nil, page=nil)
        @enctype = node['enctype'] || 'application/x-www-form-urlencoded'
        @form_node        = node
        @action           = Util::html_unescape(node['action'])
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

      # Fetch the first field whose name is equal to +field_name+
      def field(field_name)
        fields.find { |f| f.name.eql? field_name }
      end

      # Add a field with +field_name+ and +value+
      def add_field!(field_name, value = nil)
        fields << Field.new(field_name, value)
      end

      # This method sets multiple fields on the form.  It takes a list of field
      # name, value pairs.  If there is more than one field found with the
      # same name, this method will set the first one found.  If you want to
      # set the value of a duplicate field, use a value which is an Array with
      # the second value of the array as the index in to the form.  The index
      # is zero based.  For example, to set the second field named 'foo', you
      # could do the following:
      #  form.set_fields( :foo => ['bar', 1] )
      def set_fields(fields = {})
        fields.each do |k,v|
          value = nil
          index = 0
          v.each do |val|
            index = val.to_i unless value.nil?
            value = val if value.nil?
          end
          self.fields.name(k.to_s).[](index).value = value
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
      def submit(button=nil)
        @mech.submit(self, button)
      end

      # This method builds an array of arrays that represent the query
      # parameters to be used with this form.  The return value can then
      # be used to create a query string for this form.
      def build_query(buttons = [])
        query = []
    
        fields().each do |f|
          query.push(*f.query_value)
        end
    
        checkboxes().each do |f|
          query.push(*f.query_value) if f.checked
        end
    
        radio_groups = {}
        radiobuttons().each do |f|
          radio_groups[f.name] ||= []
          radio_groups[f.name] << f 
        end
    
        # take one radio button from each group
        radio_groups.each_value do |g|
          checked = g.select {|f| f.checked}
    
          if checked.size == 1
            f = checked.first
            query.push(*f.query_value)
          elsif checked.size > 1 
            raise "multiple radiobuttons are checked in the same group!" 
          end
        end

        @clicked_buttons.each { |b|
          query.push(*b.query_value)
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
        when 'multipart/form-data'
          boundary = rand_string(20)
          @enctype << "; boundary=#{boundary}"
          params = []
          query_params.each { |k,v| params << param_to_multipart(k, v) }
          @file_uploads.each { |f| params << file_to_multipart(f) }
          params.collect { |p| "--#{boundary}\r\n#{p}" }.join('') +
            "--#{boundary}--\r\n"
        else
          WWW::Mechanize.build_query_string(query_params)
        end
      end
    
      # Removes all fields with name +field_name+. 
      def delete_field!(field_name)
        @fields.delete_if{ |f| f.name == field_name}
      end
          
      private
      def parse
        @fields       = WWW::Mechanize::List.new
        @buttons      = WWW::Mechanize::List.new
        @file_uploads = WWW::Mechanize::List.new
        @radiobuttons = WWW::Mechanize::List.new
        @checkboxes   = WWW::Mechanize::List.new
    
        # Find all input tags
        (form_node/'input').each do |node|
          type = (node['type'] || 'text').downcase
          name = node['name']
          next if name.nil? && !(type == 'submit' || type =='button')
          case type
          when 'text', 'password', 'hidden', 'int'
            @fields << Field.new(node['name'], node['value'] || '') 
          when 'radio'
            @radiobuttons << RadioButton.new(node['name'], node['value'], node.has_attribute?('checked'), self)
          when 'checkbox'
            @checkboxes << CheckBox.new(node['name'], node['value'], node.has_attribute?('checked'), self)
          when 'file'
            @file_uploads << FileUpload.new(node['name'], nil) 
          when 'submit'
            @buttons << Button.new(node['name'], node['value'])
          when 'button'
            @buttons << Button.new(node['name'], node['value'])
          when 'image'
            @buttons << ImageButton.new(node['name'], node['value'])
          end
        end

        # Find all textarea tags
        (form_node/'textarea').each do |node|
          next if node['name'].nil?
          @fields << Field.new(node['name'], node.inner_text)
        end

        # Find all select tags
        (form_node/'select').each do |node|
          next if node['name'].nil?
          if node.has_attribute? 'multiple'
            @fields << MultiSelectList.new(node['name'], node)
          else
            @fields << SelectList.new(node['name'], node)
          end
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
end
