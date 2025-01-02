# frozen_string_literal: true

module OnStrum
  module Service
    module Error
      require_relative 'error/runtime'
    end

    require_relative 'version'
    require_relative 'class_methods'
    require_relative 'instance_methods'
    require_relative '../service'
  end
end
