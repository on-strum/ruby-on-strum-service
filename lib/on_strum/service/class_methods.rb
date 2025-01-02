# frozen_string_literal: true

module OnStrum
  module Service
    module ClassMethods
      def call(ctx, **args, &block)
        new(ctx, **args).execute(&block)
      end
    end
  end
end
