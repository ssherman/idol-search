module Idol
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