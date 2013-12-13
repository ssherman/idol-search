module Idol
  class Query
    include IdolAction

    action "Query"

    OPTIONAL_PARAMETERS = %w(text abridged abs_weight agent_boolean_field agent_params_field agent_security_field any_language auto_phrase case_sensitive characters cluster combine combine_number dah_end_state dah_start_state database_match delete detect_language_type dont_match_id dont_match_reference encrypt_response end_tag field_check field_recurse field_restriction field_text_field filename force_template_refresh hard_field_restriction highlight highlight_tag_term ignore_specials irs language_type match_all_terms match_encoding match_id match_language match_language_type match_reference max_date max_id max_links_per_term max_print_chars max_query_terms max_results max_score min_date min_id min_links min_score min_term_length multi_stage multi_stage_info multi_stage_min_results multi_stage_page_backward multi_stage_start_state multi_stage_total_stages output output_encoding predict print print_fields query_summary reference_field security_info sentences single_match sort spellcheck start start_tag state_dont_match_id state_match_id stemming store_state stored_state_detail stored_state_field summary synonym template template_params_csvs text_parse total_results vql weight_field_text xml_meta)  unless defined? OPTIONAL_PARAMETERS
    has_optional_params *OPTIONAL_PARAMETERS

    # SORT METHODS
    # alphabetical
    # The display order of results is determined by the string contained in fieldName. Results are displayed in alphabetical order.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a SortType field.

    # decreasing
    # The display order of results is determined by the number or string contained in fieldName. The result with the highest number or last in alphabetical order is listed first.
    # Note: For NumericType fields, this method is equivalent to numberdecreasing; for SortType fields, this method is equivalent to reversealphabetical.

    # increasing
    # The display order of results is determined by the number or string contained in fieldName. The result with the lowest number or first in alphabetical order is listed first.
    # Note: For NumericType fields, this method is equivalent to numberincreasing; for SortType fields, this method is equivalent to alphabetical.

    # numberdecreasing
    # The display order of results is determined by the number contained in fieldName. The result with the highest number is listed first.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a NumericType field.

    # numberincreasing
    # The display order of results is determined by the number contained in fieldName. The result with the lowest number is listed first.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a NumericType field.

    # reversealphabetical
    # The display order of results is determined by the string contained in fieldName. Results are displayed in reverse alphabetical order.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a SortType field.
    SORT_METHODS = ["alphabetical", "decreasing", "increasing", "numberdecreasing", "numberincreasing", "reversealphabetical"]

    # SORT OPTIONS
    # Off
    # Results are displayed unsorted.

    # AutnRank
    # Results are displayed in order of the value in their AutnRankType field. The document with the highest AutnRankType field value is listed first.

    # Cluster
    # If you have added Cluster=true to the action, the Cluster sort option allows you to display results in order of cluster (in decreasing cluster ID order).

    # Database
    # Results are displayed in order of database number (in increasing order). The database numbers are defined in IDOL server's configuration file.

    # Date
    # Results are displayed in order of their date (the date contained in the results' DateType fields). The most recent document is listed first. If several documents have the same date, their display order is determined by their autn:docid (document ID) number (the highest autn:docid is listed first).

    # DocIDDecreasing
    # Results aredisplayed in order of their autn:docid (document ID) number. The document with the highest autn:docid is listed first.

    # DocIDIncreasing
    # Results are displayed in order of their autn:docid (document ID) number. The document with the lowest autn:docid is listed first.

    # fieldName:sortMethod
    # Results are sorted according to the value of a specified field. Note that documents in which the specified field is empty are not returned.

    # fieldName
    # Specify the name of the IDOL server field whose value you want to determine the order in which the results are displayed.

    # sortMethod
    # Enter the sorting method that you want to apply to the field fieldName. The following sorting methods are available:

    # alphabetical
    # The display order of results is determined by the string contained in fieldName. Results are displayed in alphabetical order.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a SortType field.

    # decreasing
    # The display order of results is determined by the number or string contained in fieldName. The result with the highest number or last in alphabetical order is listed first.
    # Note: For NumericType fields, this method is equivalent to numberdecreasing; for SortType fields, this method is equivalent to reversealphabetical.

    # increasing
    # The display order of results is determined by the number or string contained in fieldName. The result with the lowest number or first in alphabetical order is listed first.
    # Note: For NumericType fields, this method is equivalent to numberincreasing; for SortType fields, this method is equivalent to alphabetical.

    # numberdecreasing
    # The display order of results is determined by the number contained in fieldName. The result with the highest number is listed first.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a NumericType field.

    # numberincreasing
    # The display order of results is determined by the number contained in fieldName. The result with the lowest number is listed first.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a NumericType field.

    # reversealphabetical
    # The display order of results is determined by the string contained in fieldName. Results are displayed in reverse alphabetical order.
    # Note: IDOL server can perform the sorting process more quickly if fieldName is a SortType field.

    # Random
    # Results are displayed in random order.

    # Relevance
    # Results are displayed in order of their relevance (the document with the highest is listed first). If documents have the same relevance, their display order is determined by their autn:docid (document ID) number (the highest autn:docid is listed first).

    # ReverseDate
    # Results are displayed in order of their date (the date contained in the results' DateType fields). The oldest document is listed first. If several documents have the same date, their display order is determined by their autn:docid (document ID) number (the highest autn:docid is listed first).

    # ReverseRelevance
    # Results are displayed in order of their relevance (the document with the lowest is listed first). If documents have the same relevance, their display order is determined by their autn:docid (document ID) number (the lowest autn:docid is listed first).
    SORT_OPTIONS = ["Off", "AutnRank", "Date", "DocIDDecreasing", "DocIDIncreasing", "Random", "Relevance", "ReverseDate", "ReverseRelevance"]

    def self.valid_query?(query)
      !!(query =~ /[A-Za-z0-9]+/)
    end

    def sort(value)
      unless SORT_OPTIONS.include?(value)
        raise Error.new("Unsupported sort: '#{value}'")
      end
      parameters[:sort] = value
      self
    end

    def sort_by_field(field, method)
      unless SORT_METHODS.include?(method)
        raise Error.new("Unsupported sort method: '#{method}'")
      end
      parameters[:sort] = "#{field}:#{method}"
      self
    end

    def per_page(value)
      raise Error.new "Per Page must be >= 1" if value < 1
      @per_page = value
      set_paging if @page
      self
    end

    def page(value)
      raise Error.new "Page must be >= 1" if value < 1
      @page = value
      set_paging if @per_page
      self
    end

    def abridged
      parameters[:abridged] = true
      self.parser = Parser::AbridgedResultsParser
      self
    end

    def distinct
      parameters[:abridged] = true
      self.parser = Parser::DistinctParser
      self
    end

    def summary?
      parameters.has_key?(:summary) || parameters[:summary] != 'Off'
    end

    protected

    def process_results(body)
      if @abridged
        AbridgedResultsParser.new(body).parse
      else
        super
      end
    end

    private

    def set_paging
      start((@page - 1) * @per_page + 1).max_results(@page * @per_page + 1)
    end
  end
end