module Idol
  module Parser
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
            if array_size > 0
              final_values << parsed_values[index, array_size]
            else
              final_values << []
            end
            index += array_size
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
  end
end