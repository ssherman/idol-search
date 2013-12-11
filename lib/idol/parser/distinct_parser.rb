module Idol
  module Parser
    class DistinctParser
      def initialize(result)
        @result = result
      end

      def parse
        xml = Nokogiri::XML(@result)

        fields = {:num_hits => xml.xpath('//autn:totalhits/text()').text.to_i}
        xml.xpath('//autn:abrfield').each do |field|
          names, values = parse_field(field)
          context = fields
          child = nil
          while !names.empty?
            context = child if child
            name = names.shift
            child = context[name] ||= {}
          end
          context[name] = values
        end

        fields
      end

      private

      def parse_field(field)
        names = field.xpath('autn:abrname/text()').text.split('/')
        lengths = field.xpath('autn:abrlength/text()').text.split(',').map(&:to_i)
        bytes = field.xpath('autn:abrvalue/text()').text.bytes.to_a

        values = {}
        index = 0
        lengths.each do |length|
          value = bytes[index, length].pack('C*').force_encoding("UTF-8")
          index += length
          values[value] ||= 0
          values[value] += 1
        end

        values = values.to_a.sort {|a, b| a.last == b.last ? a.first <=> b.first : a.last <=> b.last}

        [names, values]
      end
    end
  end
end