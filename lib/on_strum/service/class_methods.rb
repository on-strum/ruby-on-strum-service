# frozen_string_literal: true

module OnStrum
  module Service
    module ClassMethods
      def call(*args, **kwargs, &block)
        # For Ruby 2.7: call({key: 'value'}) -> args=[], kwargs={key: 'value'}
        # For Ruby 3.0: call({key: 'value'}) -> args=[{key: 'value'}], kwargs={}
        ctx = ::RUBY_VERSION < '3.0' && args.empty? ? kwargs : args.first
        new(ctx || {}, **kwargs).execute(&block)
      end
    end
  end
end
