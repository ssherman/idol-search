module Idol
  class List
    include IdolAction

    action 'List'

    OPTIONAL_PARAMETERS = %w(databasematch print)
    has_optional_params *OPTIONAL_PARAMETERS
  end
end