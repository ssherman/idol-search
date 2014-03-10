require_relative 'hash_from_xml'
require_relative 'filters'

module Idol
  autoload :Config, 'idol/config'
  autoload :IdolAction, 'idol/idol_action'
  autoload :Parser, 'idol/parser'
  autoload :Query, 'idol/query'
  autoload :Suggest, 'idol/suggest'
  autoload :SuggestOnText, 'idol/suggest_on_text'
  autoload :ProfileUser, 'idol/profile_user'
  autoload :Error, 'idol/exceptions'
  autoload :Encryptor, 'idol/encryptor'

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
end
