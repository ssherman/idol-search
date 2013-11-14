require 'curb'
require_relative 'hash_from_xml'
require_relative 'abridged_results_parser'
require_relative 'filters'

module Idol

  class Config
    attr_accessor :url
  end

  def self.configure(&block)
    (@config ||= Config.new).instance_eval &block
  end

  def self.config
    @config
  end

  module OptionalParams
    def has_optional_params(*params)
      params.each do |param|
        self.class_eval <<-end_eval, __FILE__, __LINE__ + 1
          def #{param}(value)
            @parameters[:#{param}] = value
            self
          end
        end_eval
      end
    end
  end

  module IdolAction
    attr_accessor :url, :filters, :parameters, :raw_results
    attr_reader :results

    def self.included(base)
      base.extend OptionalParams
      class << base
        def action(action)
          @action = action
        end

        def get_action
          @action
        end
      end
    end

    def initialize(url = nil, parameters = {})
      @raw_results = false
      @url = url || Idol.config.url
      @parameters = parameters
      @filters = FieldTextFilterCollection.new
    end

    def action
      self.class.get_action
    end

    def to_hash
      @parameters
    end

    def filters
      @filters
    end

    def execute
      return @results if @results
      post_fields = generate_post_fields

      status = nil
      body = nil

      request = Curl::Easy.new do |r|
        r.url = "#{@url}/?action=#{action}"
        r.on_complete do |data|
          status = data.response_code
          body = data.body_str
        end
      end

      request.http_post(*post_fields)
      return body if @raw_results
      @results = if @parameters[:abridged]
        AbridgedResultsParser.new(body).parse
      else
        Hash.from_xml(body)
      end
    end

    def error?
      execute[:autnresponse][:response] == 'ERROR'
    end

    def error_message
      execute[:autnresponse][:responsedata][:error][:errorstring]
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
    include IdolAction

    action "Query"

    OPTIONAL_PARAMETERS = %w(text abridged abs_weight agent_boolean_field agent_params_field agent_security_field any_language auto_phrase case_sensitive characters cluster combine combine_number dah_end_state dah_start_state database_match delete detect_language_type dont_match_id dont_match_reference encrypt_response end_tag field_check field_recurse field_restriction field_text_field filename force_template_refresh hard_field_restriction highlight highlight_tag_term ignore_specials irs language_type match_all_terms match_encoding match_id match_language match_language_type match_reference max_date max_id max_links_per_term max_print_chars max_query_terms max_results max_score min_date min_id min_links min_score min_term_length multi_stage multi_stage_info multi_stage_min_results multi_stage_page_backward multi_stage_start_state multi_stage_total_stages output output_encoding predict print print_fields query_summary reference_field security_info sentences single_match sort spellcheck start start_tag state_dont_match_id state_match_id stemming store_state stored_state_detail stored_state_field summary synonym template template_params_csvs text_parse total_results vql weight_field_text xml_meta)  unless defined? OPTIONAL_PARAMETERS
    has_optional_params *OPTIONAL_PARAMETERS

    def num_hits
      execute[:autnresponse][:responsedata][:numhits]
    end

    def hits
      execute[:autnresponse][:responsedata][:hit]
    end
  end

  class Suggest
    include IdolAction

    action "Suggest"

    OPTIONAL_PARAMETERS = %w(abs_weight case_sensitive characters cluster combine combine_number dah_end_state dah_start_state database_match delete dont_match_id dont_match_reference encrypt_response end_tag field_check field_recurse file_name force_template_refresh highlight highlight_tag_term id irs language_type match_encoding match_id match_language match_language_type match_reference max_date max_id max_print_chars max_results max_score min_date min_id min_links min_score min_term_length output output_encoding predict print print_fields query_summary reference reference_field security_info sentences single_match sort start start_tag state_dont_match_id state_id state_match_id stemming store_state stored_state_field summary template template_params_csvs timeout_ms total_results weigh_field_text xml_meta)
    has_optional_params *OPTIONAL_PARAMETERS
  end

  class SuggestOnText
    include IdolAction

    action "SuggestOnText"

    OPTIONAL_PARAMETERS = %w(abs_weight any_language case_sensitive characters cluster combine combine_number dah_end_state dah_start_state database_match delete dont_match_id dont_match_reference encrypt_response end_tag field_check field_recurse field_text file_name force_template_refresh highlight highlight_tag_term id irs language_type match_encoding match_id match_language match_language_type match_reference max_date max_id max_print_chars max_results max_score min_date min_doc_occs min_id min_links min_score min_term_length multi_stage multi_stage_info multi_stage_min_results multi_stage_page_backward multi_stage_start_state multi_stage_total_stages output output_encoding predict print print_fields query_summary reference_field security_info sentences single_match sort start start_tag state_dont_match_id state_match_id stemming store_state stored_state_field summary template text timeout_ms total_results weigh_field_text xml_meta xml_response)
    has_optional_params *OPTIONAL_PARAMETERS
  end

  class ProfileUser
    include IdolAction

    action "ProfileUser"

    OPTIONAL_PARAMETERS = [
      :defer_login, :document, :email_address, :encrypt_response,
      :file_name, :force_template_refresh, :match_threshold, :mode,
      :named_area, :output, :template, :uid, :user_name, :xml_response
    ]
    has_optional_params *OPTIONAL_PARAMETERS

    def max_terms(max)
      parameters[:DREMaxTerms] = max
      self
    end

    def min_doc_occurences(occs)
      parameters[:DREMinDocOccs] = max
      self
    end

    def only_existing(true_or_false)
      parameters[:DREOnlyExisting] = true_or_false
      self
    end

    def create_field(name, value)
      parameters[:"Field#{name}"] = value
      self
    end

    def security(name_or_type, value)
      parameters[:"Security#{name_or_type}"] = value
      self
    end
  end

end
