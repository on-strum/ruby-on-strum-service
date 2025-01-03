# frozen_string_literal: true

require_relative 'service/core'

module OnStrum
  module Service
    def self.included(base)
      base.extend(OnStrum::Service::ClassMethods)
      base.prepend(OnStrum::Service::InstanceMethods)
    end

    def audit; end

    def call
      raise OnStrum::Service::Error::Runtime, OnStrum::Service::Error::Runtime::NOT_IMPLEMENTED
    end
  end
end
