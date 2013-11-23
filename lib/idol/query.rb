module Idol
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
end