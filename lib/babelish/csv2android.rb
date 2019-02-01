module Babelish
  class CSV2Android < Csv2Base
    attr_accessor :file_path

    def initialize(filename, langs, args = {})
      super(filename, langs, args)

      @file_path = args[:output_dir].to_s
      @output_basename = args[:output_basename].to_s
    end

    def language_filepaths(language)
      require 'pathname'
      output_name = "strings.xml"
      output_name = "#{@output_basename}.xml" unless @output_basename.empty?
      # If language.code is "default", put it into values/strings.xml
      if language.code == "default"
        filepath = Pathname.new(@file_path) + "values" + output_name
      else
        region = language.region.to_s.empty? ? "" : "-#{language.region}"
        filepath = Pathname.new(@file_path) + "values-#{language.code}#{region}" + output_name
      end
      return filepath ? [filepath] : []
    end

    def process_value(row_value, default_value)
      value = super(row_value, default_value)
      # if the value begins and ends with a quote we must leave them unescapted
      if value.size > 4 && value[0, 2] == "\\\"" && value[value.size - 2, value.size] == "\\\""
        value[0, 2] = "\""
        value[value.size - 2, value.size] = "\""
      end
      value.to_utf8
    end

    ##################################################
    # Remove Emojis from String
    # https://stackoverflow.com/a/33408017/970998
    ##################################################
    def strip_emoji(text)
      text = text.force_encoding('utf-8').encode
      clean = ""

      # symbols & pics
      regex = /[\u{1f300}-\u{1f5ff}]/
      clean = text.gsub regex, ""

      # enclosed chars 
      #regex = /[\u{2500}-\u{2BEF}]/ # I changed this to exclude chinese char
      #clean = clean.gsub regex, ""

      # emoticons
      regex = /[\u{1f600}-\u{1f64f}]/
      clean = clean.gsub regex, ""

      # dingbats
      regex = /[\u{2702}-\u{27b0}]/
      clean = clean.gsub regex, ""

      # Lightning Bolt (High Voltage Sign) Emoji
      # https://emojipedia.org/emoji/%E2%9A%A1/
      regex = /\u{26A1}/
      clean = clean.gsub regex, ""

      # Variation Selector-16
      # https://emojipedia.org/emoji/%EF%B8%8F/
      regex = /\u{FE0F}/
      clean = clean.gsub regex, ""

      # cup with straw range
      regex = /[\u{1f964}-\u{1f965}]/
      clean = clean.gsub regex, ""
    end

    ##################################################
    # Remove special characters to make the Key compatible with Android
    ##################################################
    def sanitize_key(unsanitized_key)
      #puts "sanitize_key: #{unsanitized_key}"
      
      key = unsanitized_key.downcase
      key = key.gsub ' ', '_'
      key = key.gsub ' ', '_' # non-breaking space, this is not an error!
      key = key.gsub '-', '_'
      key = key.gsub '**', '__'
      key = key.gsub '\\n', '_'
      key = key.gsub '%d', 'xyz'
      key = key.gsub '%@', 'xyz'
      key = key.gsub '%1$@', 'xyz' # iOS Placeholders
      key = key.gsub '%1$d', 'xyz'
      key = key.gsub '%1$s', 'xyz'
      key = key.gsub '%1@', 'xyz'
      key = key.gsub '%2$@', 'xyz'
      key = key.gsub '%2$d', 'xyz'
      key = key.gsub '%3$s', 'xyz'
      key = key.gsub '%2@', 'xyz'
      key = key.gsub '%3$@', 'xyz'
      key = key.gsub '%3$d', 'xyz'
      key = key.gsub '%3$s', 'xyz'
      key = key.gsub '%3@', 'xyz'
      key = key.gsub '@', '_at_'

      key = key.gsub ' ', ''
      key = key.gsub '.', ''
      key = key.gsub '\'', ''
      key = key.gsub '!', ''
      key = key.gsub '?', ''
      key = key.gsub ',', ''
      key = key.gsub ':', ''
      key = key.gsub ';', ''
      key = key.gsub '+', ''
      key = key.gsub '>', ''
      key = key.gsub '<', ''
      key = key.gsub '&', ''
      key = key.gsub '[', ''
      key = key.gsub ']', ''
      key = key.gsub '(', ''
      key = key.gsub ')', ''
      key = key.gsub '/', ''
      key = key.gsub '…', ''
      key = key.gsub '%%', ''
      key = key.gsub '*', ''
      key = key.gsub '’', ''
      key = key.gsub '”', ''
      key = key.gsub '–', ''

      # Keys should not start with a digit or any of the java keywords
      if /\A\d+\z/.match(key[0,1]) || key == "continue" || key == "return" || key == "new" || key == "no"
        key = "_" + key
      end

      # Remove Emojis from Key
      key = strip_emoji(key)

      #puts "sanitized_key: #{key}"
      return key
    end

    ##################################################
    # Replace characters with Android compatible ones (e.g. "&" -> "&amp;")
    ##################################################
    def sanitize_value(unsanitized_value)
      #puts "unsanitized_value: #{unsanitized_value}"
      value = unsanitized_value
      value = value.gsub "'", %q(\\\') # replaces ['] with [\']
      #value = value.gsub '"', '\\"' # replaces ["] with [\"] TODO is this correct?
      # replace iOS Placeholder characters with Android Placeholder characters
      value = value.gsub '%1$@', '%1$s'
      value = value.gsub '%1@', '%1$s'
      value = value.gsub '%2$@', '%2$s'
      value = value.gsub '%2@', '%2$s'
      value = value.gsub '%3$@', '%3$s'
      value = value.gsub '%3@', '%3$s'
      value = value.gsub '%@', '%1$s' 
      value = value.gsub '&', '&amp;'
      value = value.gsub '<', '&lt;'
      value = value.gsub '>', '&gt;'
      value = value.gsub '', '' # 0x3 Unicode control character
      value = value.gsub '', '' # 0x13 Unicode control character
      value = value.gsub ' ', ' ' # replace non-breaking space with normal space
      value = value.gsub '...', '…' # replace 3 dots with suggested char
      value = value.gsub '100%%', '100%' # replace 100%% with 100%
      value = value.gsub '**', '\"'
      value = value.gsub '”', '\"' # weird

      if unsanitized_value != value
        #puts "changed: #{unsanitized_value} \n-> #{value}"
      end
      #puts "value: #{value}"
      return value
    end

    ##################################################
    # 
    ##################################################
    def get_row_format(row_key, row_value, comment = nil, indentation = 0)
      #puts "#{row_key}; #{row_value}; #{comment}; #{indentation}"
      sanitized_row_key = sanitize_key(row_key)
      sanitized_row_value = sanitize_value(row_value)
      #puts "sanitized_row_key: #{sanitized_row_key}"
      #puts "sanitized_row_value: #{sanitized_row_value}"


      entry = comment.to_s.empty? ? "" : "\n\t<!-- #{comment} -->\n"
      entry + "    <string name=\"#{sanitized_row_key}\">#{sanitized_row_value}</string>\n"
    end

    def hash_to_output(content = {})
      output = ''
      if content && content.size > 0
        output += "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        output += "<resources>\n"
        content.each do |key, value|
          comment = @comments[key]
          output += get_row_format(key, value, comment)
        end
        output += "</resources>\n"
      end
      return output
    end

    def extension
      "xml"
    end
  end
end
