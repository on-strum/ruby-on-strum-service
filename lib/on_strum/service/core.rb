# frozen_string_literal: true

module OnStrum
  module Service
    WARNING = <<~MESSAGE
      📢 Note: You have both Strum::Service and OnStrum::Service installed.
      You can safely migrate your services by replacing:
        include Strum::Service
      with:
        include OnStrum::Service

      All public APIs and behavior are fully compatible!
    MESSAGE

    module Error
      require_relative 'error/runtime'
    end

    require_relative 'version'
    require_relative 'class_methods'
    require_relative 'instance_methods'
    require_relative '../service'
  end
end
