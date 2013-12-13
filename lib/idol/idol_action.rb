require 'faraday'
require 'cgi'
module Idol
  module IdolAction
    attr_accessor :url, :filters, :parameters, :raw_results, :parser
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

    def adapter(adapter)
      @adapter = adapter
      self
    end

    def dup
      action = self.class.new(url, parameters.dup)
      action.adapter(@adapter)
      action.filters = filters.dup
      action
    end

    Conjunctions.constants.each do |conjunction|
      self.class_eval <<-end_eval, __FILE__, __LINE__ + 1
        def #{conjunction.to_s.downcase}
          @next_conjunction = Conjunctions::#{conjunction}
          self
        end
      end_eval
    end

    Filters.constants.each do |filter|
      self.class_eval <<-end_eval, __FILE__, __LINE__ + 1
        def #{filter.to_s.downcase}(field, *values)
          add_field(Filters::#{filter}, field, values)
        end
      end_eval
    end

    def remove_parameter(name)
      parameters.delete(name)
      self
    end

    def to_url
      u = "#{@url}/?action=#{action}"
      u << "&fieldtext=#{CGI.escape(@filters.to_idol_syntax)}" if filters.count > 0
      parameters.each do |name, values|
        u << "&#{name.to_s.gsub("_", "")}=#{CGI.escape(values.to_s)}"
      end
      u
    end

    def execute
      return @results if @results

      adapter = @adapter || Idol.config.adapter || Faraday.default_adapter
      Idol.config.logger.debug { "Executing query #{to_url} with adapter: #{adapter}" } if Idol.config.logger
      response = Faraday.new(:url => "#{@url}/?action=#{action}") do |r|
        generate_post_fields(r.params)
        r.adapter adapter
      end.post
      status = response.status
      body = response.body

      @results = process_results(body)
    end

    def error?
      execute[:autnresponse][:response] == 'ERROR'
    end

    def error_message
      execute[:autnresponse][:responsedata][:error][:errorstring]
    end

    protected

    def process_results(body)
      if @raw_results
        body
      elsif parser
        parser.new(body).parse
      else
        Hash.from_xml(body)
      end
    end

    private
    def generate_post_fields(post_fields)
      if @filters.count > 0
        post_fields["fieldtext"] = @filters.to_idol_syntax
      end

      @parameters.each do |name, values|
        post_fields[name.to_s.gsub("_", "")] = values
      end
    end

    def add_field(filter, field, value)
      conjunction = Conjunctions::AND
      if @next_conjunction
        conjunction = @next_conjunction
        @next_conjunction = nil
      end
      filters.add(FieldTextFilter.new(field, filter, value), conjunction)
      self
    end
  end
end