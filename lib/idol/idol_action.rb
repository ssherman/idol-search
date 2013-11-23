require 'faraday'
require 'eventmachine'
module Idol
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

      adapter = EM.reactor_running? ? :em_synchrony : Faraday.default_adapter

      response = Faraday.new(:url => "#{@url}/?action=#{action}") do |r|
        generate_post_fields(r.params)
        r.adapter adapter
      end.post
      status = data.status
      body = data.body

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
    def generate_post_fields(post_fields)
      if @filters.count > 0
        post_fields["fieldtext"] = @filters.to_idol_syntax
      end

      @parameters.each do |name, values|
        post_fields[name.to_s.gsub("_", "")] = values
      end
    end
  end
end