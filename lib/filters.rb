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