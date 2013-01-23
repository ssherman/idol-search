require 'curb'
require_relative 'hash_from_xml'
module Idol

  module Conjunctions
    AND = "AND"
    OR = "OR"
    NOT = "NOT"
    BEFORE = "BEFORE"
    AFTER = "AFTER"
  end

  module Filters
    MATCH = "MATCH"
    EQUAL = "EQUAL"
    GREATER = "GREATER"
    LESS = "LESS"
    NRANGE = "NRANGE"
    NOT_EQUAL = "NOTEQUAL"
    WILD = "WILD"

    MATCH_ALL = "MATCHALL"
    EQUAL_ALL = "EQUALALL"

    NOT_MATCH = "NOTMATCH"
    NOT_STRING = "NOTSTRING"
    NOT_WILD = "NOTWILD"

    STRING = "STRING"
    STRING_ALL = "STRINGALL"
    SUBSTRING = "SUBSTRING"

    TERM = "TERM"
    TERM_ALL = "TERMALL"
    TERM_EXACT = "TERMEXACT"
    TERM_EXACT_ALL = "TERMEXACTALL"
    TERM_EXACT_PHRASE = "TERMEXACTPHRASE"
    TERM_PHRASE = "TERMPHRASE"
  end

  module OptionalParams
    def has_optional_params(*params)
      params.flatten.each do |opt_param|

        # write the value to params
        define_method :"#{opt_param}" do |value|
          instance_variable_set("@#{opt_param}", value)
          self.class.send(:attr_accessor, opt_param)
          @parameters[opt_param.gsub("_", "")] = value
          return self
        end

      end
    end
  end



  module BasicIdolFunctionality
    attr_accessor :url, :filters, :parameters, :raw_results
    attr_reader :action

    def initialize(url, parameters = {})
      @raw_results = false
      @url = url
      @parameters = parameters
      @filters = FieldTextFilterCollection.new
    end

    def filters
      @filters
    end    

    def execute
      post_fields = generate_post_fields

      status = nil
      body = nil

      request = Curl::Easy.new do |r|
        r.url = "#{@url}/?action=#{@action}"
        r.on_complete do |data|
          status = data.response_code
          body = data.body_str
        end
      end

      request.http_post(*post_fields)
      return body if @raw_results
      results = if abridged
        AbridgedResultsParser.new(body).parse
      else
        Hash.from_xml(body)
      end
      results
    end

    private
    def generate_post_fields
      post_fields = []
      if @filters.count > 0
        post_fields << Curl::PostField.content("fieldtext", @filters.to_idol_syntax)
      end

      @parameters.each do |name, values|
        post_fields << Curl::PostField.content(name, values)
      end
      post_fields
    end
  end

  class AbridgedResultsParser
    attr_accessor :result, :parsed_result
    def initialize(result)
      @result = result
    end

    def parse
      fields = []
      autoparsed_result = Hash.from_xml(@result)
      xml = Nokogiri::XML(@result)

      autn_ids = xml.xpath('//autn:abrid').first.content.split(",")
      weights = xml.xpath('//autn:abrweight')[0].content.split(',').map{|w|w.to_i}

      # parse out the field meta data
      xml.xpath('//autn:abrfield').each do |field_data|
        name = field_data.xpath('autn:abrname')[0].content
        lengths = field_data.xpath('autn:abrlength')[0].content.split(',').map{|l| l.to_i }
        values = field_data.xpath('autn:abrvalue')[0].content.strip
        array_size_of_values = field_data.xpath('autn:abrnumber')[0].content.split(',').map{|n| n.to_i }
        
        current_values_position = 0
        parsed_values = []

        # the abridged results store everything in a big long string with the lengths to
        # split on in a different comma seperated string. so it's parse out the values based
        # on the value length
        lengths.each do |length|
          parsed_values << values[current_values_position, length]
          current_values_position += length
        end

        # if the value is an array there's some additional magic that needs to be done to get the right array value
        final_values = []
        index = 0
        array_size_of_values.each do |array_size|
          if array_size == 1
            final_values << parsed_values[index]
          elsif array_size > 1
            final_values << parsed_values[index, array_size]
          end
          index += 1
        end

        fields << {:name => name, :values => final_values} 
      end

      normalized_results = []
      index = 0

      # build a hash that mimics the hash from the unabridged normal results
      autn_ids.each do |id|
        result = {:id => id, :weight => weights[index], :content => {}}
        fields.each do |field|
          section, name = field[:name].split("/")
          unless result[:content].has_key?(section)
            result[:content][section] = {}
          end
          result[:content][section][name] = field[:values][index]
        end
        normalized_results << result
        index += 1
      end

      response_data = autoparsed_result[:autnresponse][:responsedata]
      response_data[:hit] = normalized_results
      response_data.delete(:abrid)
      response_data.delete(:abrweight)
      response_data.delete(:abrfield)
      @parsed_result = autoparsed_result
      @parsed_result
    end
  end

  class Query
    extend OptionalParams
    include BasicIdolFunctionality
    OPTIONAL_PARAMETERS = %w(text abridged abs_weight agent_boolean_field agent_params_field agent_security_field any_language auto_phrase case_sensitive characters cluster combine combine_number dah_end_state dah_start_state database_match delete detect_language_type dont_match_id dont_match_reference encrypt_response end_tag field_check field_recurse field_restriction field_text_field filename force_template_refresh hard_field_restriction highlight highlight_tag_term ignore_specials irs language_type match_all_terms match_encoding match_id match_language match_language_type match_reference max_date max_id max_links_per_term max_print_chars max_query_terms max_results max_score min_date min_id min_links min_score min_term_length multi_stage multi_stage_info multi_stage_min_results multi_stage_page_backward multi_stage_start_state multi_stage_total_stages output output_encoding predict print print_fields query_summary reference_field security_info sentences single_match sort spellcheck start start_tag state_dont_match_id state_match_id stemming store_state stored_state_detail stored_state_field summary synonym template template_params_csvs text_parse total_results vql weight_field_text xml_meta)  unless defined? OPTIONAL_PARAMETERS
    has_optional_params OPTIONAL_PARAMETERS
    def initialize(url, parameters = {})
      super
      @action = "Query"
    end

  end

  class Suggest
    extend OptionalParams
    include BasicIdolFunctionality
    OPTIONAL_PARAMETERS = %w(abs_weight case_sensitive characters cluster combine combine_number dah_end_state dah_start_state database_match delete dont_match_id dont_match_reference encrypt_response end_tag field_check field_recurse file_name force_template_refresh highlight highlight_tag_term id irs language_type match_encoding match_id match_language match_language_type match_reference max_date max_id max_print_chars max_results max_score min_date min_id min_links min_score min_term_length output output_encoding predict print print_fields query_summary reference reference_field security_info sentences single_match sort start start_tag state_dont_match_id state_id state_match_id stemming store_state stored_state_field summary template template_params_csvs timeout_ms total_results weigh_field_text xml_meta)
    has_optional_params OPTIONAL_PARAMETERS
    def initialize(url, parameters = {})
      super
      @action = "Suggest"
    end
  end

  class FieldTextFilter
    attr_accessor :fields, :specifier, :values
    def initialize(fields, specifier, values)
      @fields = fields.is_a?(Array) ? fields : [fields]
      @specifier = specifier
      @values = values.is_a?(Array) ? values : [values]
    end

    def to_idol_syntax
      values_string = @values.map{|v| escape(v) }.join(",")
      "#{specifier}{#{values_string}}:#{fields.join(':')}"
    end

    private
    def escape(value)
      value.gsub("&", "%26").gsub("\\", "%5C").gsub("%", "%25").gsub("{", "%257B").gsub("{", "%257D")
    end
  end

  class FieldTextFilterCollection
    include Enumerable
    def initialize
      @filters = []
      @conjunctions = []
    end

    def <<(filter)
      @filters << filter
    end
    
    def add(filter, conjunction=Idol::Conjunctions::AND)
      self << filter
      @conjunctions << conjunction
      return self
    end

    def each(&block)
      @filters.each(&block)
    end

    def to_idol_syntax
      idol_syntax = []
      @filters.each_with_index do |filter, index|
        idol_syntax << @conjunctions[index] unless index == 0
        idol_syntax << filter.to_idol_syntax
      end
      idol_syntax.join(" ").strip
    end

  end

end
