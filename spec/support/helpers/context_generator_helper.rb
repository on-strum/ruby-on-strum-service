# frozen_string_literal: true

module ContextGeneratorHelper
  def call_service(service_class, input, **args)
    service_class.call(input, **args) do |monad|
      monad.success { |result| result }
      monad.failure { |errors| errors }
    end
  end

  def call_service_with_error_param(service_class, input, error_param)
    service_class.call(input) do |m|
      m.success { |result| result }
      m.failure(error_param) { |errors| errors }
      m.failure(:other_param) { 'Other param failure' }
      m.failure { 'Default failure' }
    end
  end
end
