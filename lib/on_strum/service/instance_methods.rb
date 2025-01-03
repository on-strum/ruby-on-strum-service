# frozen_string_literal: true

module OnStrum
  module Service
    module InstanceMethods
      COERCIVE_METHODS = %i[add_error add_errors any required sliced sliced_list].freeze
      DEFAULT_CTX_KEY = :default

      def initialize(ctx, **args)
        self.errors = ::Hash.new { |hash, key| hash[key] = [] }
        self.handlers = { on: {}, success: {}, failure: {} }
        self.outputs = {}
        self.inputs = args.merge(OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY => ctx)
        self.inputs_snapshot = inputs.dup.freeze
        init_default_proc
      end

      def execute
        catch(:exit) do
          yield(self) if block_given?
          audit
          call if valid?
        end
        valid? ? valid_result : invalid_result
      end

      def hook(name, data = self)
        handlers_on_name = handlers.dig(:on, name)
        handlers_on_name.is_a?(::Proc) && handlers_on_name.call(data)
      end

      def valid?
        errors.empty?
      end

      def on(direction, &block)
        handlers[:on][direction] = block
      end

      def success(direction = nil, &block)
        handlers[:success][direction] = block
      end

      def failure(direction = nil, &block)
        handlers[:failure][direction] = block
      end

      def method_missing(method_name, *_args, &_block)
        if from_input?(method_name)
          input[method_name]
        elsif from_inputs?(method_name)
          inputs[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        from_input?(method_name) || from_inputs?(method_name) || super
      end

      protected

      attr_accessor :inputs, :inputs_snapshot, :errors, :outputs, :handlers

      def input
        inputs[OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY]
      end

      def input=(value)
        inputs[OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY] = value
      end

      def input_snapshot
        inputs_snapshot[OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY]
      end

      def audit; end

      def args
        inputs.slice(*inputs.keys - [OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY])
      end

      def output_value(key = OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY)
        @outputs[key]
      end

      def output(key = OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY, value) # rubocop:disable Style/OptionalArguments
        @outputs[key] = value
      end

      def add_error(field, value)
        errors[field] += Array(value)
      end

      def add_errors(errors)
        errors.each { |field, value| add_error(field, value) }
      end

      def required(*keys)
        return add_error(:input, :must_be_hash) unless input_hash?

        (keys - service_keys).each { |key| add_error(key, :field_must_exist) }
      end

      def any(*keys)
        return add_error(:input, :must_be_hash) unless input_hash?

        add_error(:input, :any_field_must_exist) if (keys & service_keys).empty?
      end

      def sliced(*keys)
        return add_error(:input, :must_be_hash) unless input_hash?

        self.input = input.merge(args).slice(*keys)
      end

      def sliced_list(*keys)
        add_error(:input, :must_be_array) && return unless input.is_a?(::Array)
        add_error(:input_subitem, :must_be_hash) && return unless input.all?(::Hash)

        self.input = input.map { |item| item.slice(*keys) }
      end

      def service_keys
        input.keys | args.keys
      end

      OnStrum::Service::InstanceMethods::COERCIVE_METHODS.each do |method_name|
        define_method(:"#{method_name}!") do |*args, **kwargs, &block|
          send(method_name, *args, **kwargs, &block)
          throw :exit unless valid?
        end
      end

      private

      def method_s_sym(method_name)
        [method_name.to_s, method_name.to_sym]
      end

      def from_input?(method_name)
        method_key, method_sym = method_s_sym(method_name)
        args.empty? && input_hash? && (input.key?(method_key) || input.key?(method_sym))
      end

      def from_inputs?(method_name)
        method_key, method_sym = method_s_sym(method_name)
        inputs.key?(method_key) || inputs.key?(method_sym)
      end

      def input_hash?
        input.is_a?(::Hash)
      end

      def default_proc
        proc do |hash, key| # string lookup in case accessing to hash by symbol
          key = key.to_s
          hash.key?(key) ? hash[key] : nil
        end
      end

      def init_default_proc
        inputs.default_proc = default_proc
        input.default_proc = default_proc if input_hash?
      end

      def handler_key
        ((outputs.keys << nil) & handlers[:success].keys).first
      end

      def valid_result
        result = outputs[handler_key] || outputs[OnStrum::Service::InstanceMethods::DEFAULT_CTX_KEY]
        handler = handlers[:success][handler_key]
        return result unless handler.is_a?(::Proc)

        handler.call(result)
      end

      def invalid_result
        handlers_failure = handlers[:failure]
        handler = handlers_failure[((errors.values.flatten << nil) & handlers_failure.keys).first]
        handler.call(errors) if handler.is_a?(::Proc)
      end
    end
  end
end
