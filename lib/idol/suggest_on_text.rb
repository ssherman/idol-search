module Idol
  class SuggestOnText
    include IdolAction

    action "SuggestOnText"

    OPTIONAL_PARAMETERS = %w(abs_weight any_language case_sensitive characters cluster combine combine_number dah_end_state dah_start_state database_match delete dont_match_id dont_match_reference encrypt_response end_tag field_check field_recurse field_text file_name force_template_refresh highlight highlight_tag_term id irs language_type match_encoding match_id match_language match_language_type match_reference max_date max_id max_print_chars max_results max_score min_date min_doc_occs min_id min_links min_score min_term_length multi_stage multi_stage_info multi_stage_min_results multi_stage_page_backward multi_stage_start_state multi_stage_total_stages output output_encoding predict print print_fields query_summary reference_field security_info sentences single_match sort start start_tag state_dont_match_id state_match_id stemming store_state stored_state_field summary template text timeout_ms total_results weigh_field_text xml_meta xml_response)
    has_optional_params *OPTIONAL_PARAMETERS
  end
end