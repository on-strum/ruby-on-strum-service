# frozen_string_literal: true

require_relative 'service/core'

module OnStrum
  module Service
    def self.included(base)
      base.extend(OnStrum::Service::ClassMethods)
      base.include(OnStrum::Service::InstanceMethods)

      ::Kernel.warn(OnStrum::Service::WARNING) if defined?(Strum::Service)
    end

    def call
      raise OnStrum::Service::Error::Runtime, OnStrum::Service::Error::Runtime::NOT_IMPLEMENTED
    end
  end
end
