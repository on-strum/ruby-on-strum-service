# frozen_string_literal: true

RSpec.describe OnStrum::Service do
  describe 'service context behavior' do
    subject(:service_call) do
      call_service(
        service,
        {},
        service_argument_one: service_argument_one,
        service_argument_two: service_argument_two
      )
    end

    let(:service_argument_one) { 41 }
    let(:service_argument_two) { 1 }
    let(:service) do
      ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) { output(service_argument_one + service_argument_two) }
      end
    end

    it 'creates methods named as keyword arguments' do
      expect(service_call).to eq(42)
    end
  end

  describe 'coercive exit behavior' do
    it 'add error' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:a, :force)
          add_error!(:a, :exit)
          add_error(:b, :exit)
        end
      end

      expect(call_service(service_class, {})).to eq(a: %i[force exit])
    end

    it 'add errors' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:b, :force)
          add_errors!(a: %i[force exit])
          add_error(:b, :exit)
        end
      end

      expect(call_service(service_class, {})).to eq(b: [:force], a: %i[force exit])
    end

    it 'required' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          required!(:b)
          add_error(:b, :i_break_rules)
        end
      end

      expect(call_service(service_class, { a: 1 })).to eq(b: [:field_must_exist])
    end

    it 'audit' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) { |_| audit }

        define_method(:audit) do
          required(:b)
        end
      end

      expect(call_service(service_class, { a: 1 })).to eq(b: [:field_must_exist])
    end

    it 'throw exception' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:b, :force)
          throw :some_error
        end
      end

      expect { call_service(service_class, {}) }.to throw_symbol(:some_error)
    end
  end

  describe 'failure default behavior' do
    it 'one key - one error' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) { add_error(:err_key, :err_val) }
      end

      expect(call_service(service_class, {})).to eq(err_key: [:err_val])
    end

    it 'one key - few errors' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:err_key, :err_val1)
          add_error(:err_key, :err_val2)
        end
      end

      expect(call_service(service_class, {})).to eq(err_key: %i[err_val1 err_val2])
    end

    it 'two keys with one error' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:err_key1, :err_val1)
          add_error(:err_key2, :err_val2)
        end
      end

      expect(call_service(service_class, {})).to eq(err_key1: [:err_val1], err_key2: [:err_val2])
    end

    it 'two keys with two errors' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:err_key1, :err_val1)
          add_error(:err_key1, :err_val2)
          add_error(:err_key2, :err_val1)
          add_error(:err_key2, :err_val2)
        end
      end

      expect(call_service(service_class, {})).to eq(err_key1: %i[err_val1 err_val2], err_key2: %i[err_val1 err_val2])
    end
  end

  describe 'failure with param behavior' do
    it 'basic behavior' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) { add_error(:err_key, :err_val) }
      end

      expect(call_service_with_error_param(service_class, {}, :err_val)).to eq(err_key: [:err_val])
    end

    it 'multi params order' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:err_key, :err_val)
          add_error(:err_key, :other_param)
        end
      end

      expect(call_service_with_error_param(service_class, {}, :err_val)).to eq(err_key: %i[err_val other_param])
    end

    it 'multi params incorrect order' do
      service_class = ::Class.new do
        include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        define_method(:call) do
          add_error(:err_key, :other_param)
          add_error(:err_key, :err_val)
        end
      end

      expect(call_service_with_error_param(service_class, {}, :err_val)).to eq('Other param failure')
    end
  end

  describe 'service class behavior' do
    context 'when service class is empty' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
          define_method(:call) {} # rubocop:disable Lint/EmptyBlock
        end.call({})
      end

      it { is_expected.to be_nil }
    end

    context 'when method is missing' do
      context 'when method args is empty and context includes method name key' do
        subject(:service_class) do
          ::Class.new do
            include OnStrum::Service # rubocop:disable RSpec/DescribedClass
            define_method(:call) do
              hook(:olo, 42)
              output(target_method)
            end
          end
        end

        let(:service_object_context) { 'service_object_context' }

        it do
          service_class.call({ target_method: service_object_context }) do |monad|
            monad.success do |result|
              expect(monad.respond_to?(:target_method)).to be(true)
              expect(result).to eq(service_object_context)
            end
          end
        end
      end

      context 'when method args is not empty and context includes method name key' do
        subject(:service_class) do
          ::Class.new do
            include OnStrum::Service # rubocop:disable RSpec/DescribedClass
            define_method(:call) do
              output(target_method(42))
            end
          end
        end

        let(:service_object_context) { 'service_object_context' }
        let(:service_object_args) { 'service_object_args' }

        it do
          service_class.call({ target_method: service_object_context }, target_method: service_object_args) do |monad|
            monad.success do |result|
              expect(monad.respond_to?(:target_method)).to be(true)
              expect(result).to eq(service_object_args)
            end
          end
        end
      end

      context 'when method args is empty and context does not include method name key' do
        subject(:service_class) do
          ::Class.new do
            include OnStrum::Service # rubocop:disable RSpec/DescribedClass
            define_method(:call) do
              output(target_method)
            end
          end
        end

        let(:service_object_context) { 'service_object_context' }
        let(:service_object_args) { 'service_object_args' }

        it do
          service_class.call({ target_method_: service_object_context }, target_method: service_object_args) do |monad|
            monad.success do |result|
              expect(result).to eq(service_object_args)
            end
          end
        end
      end

      context 'when method not found' do
        subject(:service_class) do
          ::Class.new do
            include OnStrum::Service # rubocop:disable RSpec/DescribedClass
            define_method(:call) { not_existent_method }
          end
        end

        it 'raises NameError exception' do
          expect { service_class.call([]) }.to raise_error(
            ::NameError,
            /undefined local variable or method `not_existent_method'/
          )
        end
      end
    end

    context 'overriding input' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass

          define_method(:call) do
            sliced(:a)
            self.input = 42
          end
        end
      end

      it do
        service_class.call({ context: 'service_object_context' }) do |monad|
          monad.success do |_result|
            expect(monad.send(:input)).to eq(42)
            expect(monad.send(:input_snapshot)).to eq(context: 'service_object_context')
            expect(monad.send(:output_value)).to be_nil
          end
        end
      end
    end

    context 'helper sliced' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass

          define_method(:call) do
            sliced(:a, :b)
          end
        end
      end

      it 'merges context with args, slices, overrides input' do
        service_class.call({ a: 'service_object_context', c: 12 }, b: 'service_object_args', d: 27) do |monad|
          monad.success do |_result|
            expect(monad.send(:input)).to eq(a: 'service_object_context', b: 'service_object_args')
          end
        end
      end
    end

    context 'helper sliced_list' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass

          define_method(:call) do
            sliced_list(:a, :b)
          end
        end
      end

      context 'when input is not an array' do
        it 'returns an error' do
          service_class.call({}) do |monad|
            monad.failure { |error| expect(error).to eq(input: %i[must_be_array]) }
          end
        end
      end

      context 'when input is an array' do
        context 'when all items are hash' do
          it 'slises each element of input' do
            service_class.call([{ a: 42 }, { b: 13 }, { c: 100 }]) do |monad|
              monad.success do |_result|
                expect(monad.send(:input)).to eq(
                  [
                    { a: 42 },
                    { b: 13 },
                    {}
                  ]
                )
              end
            end
          end
        end

        context 'when input includes not a hashes' do
          it 'returns an error' do
            input = [{}, 42]
            service_class.call(input) do |monad|
              expect(monad.send(:input)).to eq(input)
              monad.failure { |error| expect(error).to eq(input_subitem: %i[must_be_hash]) }
            end
          end
        end
      end
    end

    context 'hook' do
      context 'when hook called inside service object' do
        subject(:service_class) do
          ::Class.new do
            include OnStrum::Service # rubocop:disable RSpec/DescribedClass
            define_method(:call) do
              hook(:hook_one)
              hook(:hook_two, 42)
              output(true)
            end
          end
        end

        it do
          service_class.call({}) do |monad|
            monad.success { |result| expect(result).to be(true) }
            monad.on(:hook_one) { |hook_context| expect(hook_context).to eq(monad) }
            monad.on(:hook_two) { |hook_context| expect(hook_context).to eq(42) }
          end
        end
      end

      context 'when hook called outside service object' do
        subject(:service_class) do
          ::Class.new do
            include OnStrum::Service # rubocop:disable RSpec/DescribedClass
            define_method(:call) do
              output(true)
            end
          end
        end

        it do
          service_class.call({}) do |monad|
            monad.hook(:hook_one, 42)
            monad.success { |result| expect(result).to be(true) }
            monad.on(:hook_one) { |hook_context| expect(hook_context).to eq(42) }
          end
        end
      end
    end

    context 'helper any' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
          define_method(:call) do
            any(:some_key)
          end
        end
      end

      context 'when context is not a hash' do
        it do
          service_class.call(42) do |monad|
            monad.failure { |error| expect(error).to eq(input: %i[must_be_hash]) }
          end
        end
      end

      context 'when context is a hash' do
        it do
          service_class.call({ a: 42 }, b: 13) do |monad|
            monad.failure { |error| expect(error).to eq(input: %i[any_field_must_exist]) }
          end
        end
      end
    end

    context 'helper input/inputs, method lookup' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
          define_method(:call) do
            output(method_name)
          end
        end
      end

      context 'when methods from service object context, includes string and symbol same keys' do
        it 'returns symbol-key value' do
          service_class.call({ 'method_name' => 42, method_name: 100 }) do |monad|
            monad.success { |result| expect(result).to eq(100) }
          end
        end
      end

      context 'when methods from service object context, includes string key' do
        it 'returns sstring-key value' do
          service_class.call({ 'method_name' => 42 }) do |monad|
            monad.success { |result| expect(result).to eq(42) }
          end
        end
      end

      context 'when methods from service object args, includes string and symbol same keys' do
        it 'returns symbol-key value' do
          service_class.call({}, 'method_name' => 42, method_name: 100) do |monad|
            monad.success { |result| expect(result).to eq(100) }
          end
        end
      end

      context 'when methods from service object args, includes string key' do
        it 'returns sstring-key value' do
          service_class.call({}, 'method_name' => 42) do |monad|
            monad.success { |result| expect(result).to eq(42) }
          end
        end
      end
    end

    context 'when call method dos not implemented' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
        end
      end

      it 'raises runtime error' do
        expect { service_class.call({}) }.to raise_exception(
          OnStrum::Service::Error::Runtime,
          OnStrum::Service::Error::Runtime::NOT_IMPLEMENTED
        )
      end
    end
  end

  context 'method_missing behavior' do
    context 'when key exists in input and args is empty' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
          define_method(:call) do
            output(test_key)
          end
        end
      end

      it 'returns value from input when input is hash' do
        service_class.call({ test_key: 'from_input' }) do |monad|
          monad.success do |result|
            expect(result).to eq('from_input')
          end
        end
      end
    end

    context 'when key exists in inputs' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
          define_method(:call) do
            output(test_key)
          end
        end
      end

      it 'returns value from inputs when not found in input or args not empty' do
        service_class.call({}, test_key: 'from_inputs') do |monad|
          monad.success do |result|
            expect(result).to eq('from_inputs')
          end
        end
      end

      it 'returns value from inputs when input is not a hash' do
        service_class.call([], test_key: 'from_inputs') do |monad|
          monad.success do |result|
            expect(result).to eq('from_inputs')
          end
        end
      end
    end

    context 'when method does not exist anywhere' do
      subject(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
          define_method(:call) do
            non_existent_method
          end
        end
      end

      it 'raises NameError through super' do
        expect { service_class.call({}) }.to raise_error(::NameError)
      end
    end

    context 'respond_to? behavior matches method_missing' do
      let(:service_class) do
        ::Class.new do
          include OnStrum::Service # rubocop:disable RSpec/DescribedClass
          def call; end
        end
      end

      context 'when args are not empty' do
        subject(:service) { service_class.new({ input_key: 'value' }, inputs_key: 'value') }

        it do
          expect(service.respond_to?(:input_key)).to be(false)
          expect(service.respond_to?(:inputs_key)).to be(true)
          expect(service.respond_to?(:non_existent)).to be(false)
        end
      end

      context 'when args are empty' do
        subject(:service) { service_class.new({ input_key: 'value' }) }

        it { expect(service.respond_to?(:input_key)).to be(true) }
      end
    end
  end
end
