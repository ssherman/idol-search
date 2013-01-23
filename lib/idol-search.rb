require 'curb'
require_relative 'hash_from_xml'
require_relative 'abridged_results_parser'
require_relative 'filters'

module Idol

  module OptionalParams
    def has_optional_params(*params)
      params.flatten.each do |opt_param|

        # write the value to params
        define_method :"#{opt_param}" do |value|
          @parameters[opt_param.to_sym] = value
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

    def to_hash
      @parameters
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
      results = if @parameters[:abridged]
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
        post_fields << Curl::PostField.content(name.to_s.gsub("_", ""), values)
      end
      post_fields
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


end
