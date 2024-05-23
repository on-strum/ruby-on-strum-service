# frozen_string_literal: true

module OnStrum
  module Service
    def self.included(base)
      base.extend(OnStrum::Service::ClassMethods)
      base.prepend(OnStrum::Service::InstanceMethods)
    end

    def call
      raise OnStrum::Service::Error::Runtime, OnStrum::Service::Error::Runtime::NOT_IMPLEMENTED
    end
  end
end
