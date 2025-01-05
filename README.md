# `on_strum-service` - Abstract class for service object scaffolding

[![Maintainability](https://api.codeclimate.com/v1/badges/21c27943474cd252eb1d/maintainability)](https://codeclimate.com/github/on-strum/ruby-on-strum-service/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/21c27943474cd252eb1d/test_coverage)](https://codeclimate.com/github/on-strum/ruby-on-strum-service/test_coverage)
[![CircleCI](https://circleci.com/gh/on-strum/ruby-on-strum-service/tree/master.svg?style=svg)](https://circleci.com/gh/on-strum/ruby-on-strum-service/tree/master)
[![Gem Version](https://badge.fury.io/rb/on_strum-service.svg)](https://badge.fury.io/rb/on_strum-service)
[![Downloads](https://img.shields.io/gem/dt/on_strum-service.svg?colorA=004d99&colorB=0073e6)](https://rubygems.org/gems/on_strum-service)
[![GitHub](https://img.shields.io/github/license/on-strum/ruby-on-strum-service)](LICENSE.txt)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

`on_strum-service` is a lightweight Ruby gem that provides an elegant and structured way to implement the Service Object pattern. It offers a robust foundation for encapsulating business logic, handling complex operations, and maintaining clean, maintainable code.

Following a monadic approach, it ensures predictable flow control and error handling, making it easy to chain operations and handle both success and failure cases explicitly. With built-in error handling, input validation, and a flexible hook system, it simplifies the creation of service objects while promoting best practices in Ruby applications.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)
- [Credits](#credits)
- [Versioning](#versioning)
- [Changelog](CHANGELOG.md)

## Features

- **Simple and Intuitive API**: Create service objects with a clean, straightforward syntax
- **Monadic Result Handling**: Explicit success/failure paths inspired by functional programming concepts
- **Built-in Error Handling**: Error management system with support for multiple errors per key
- **Input Validation**: Easy validation of required fields and input parameters
- **Flexible Context System**: Access input parameters directly as methods with method_missing support
- **Hook System**: Register and handle events during service execution
- **Input Processing Helpers**: Utilities for handling arrays, hashing slicing, and data transformation
- **Chainable Results**: Process success and failure outcomes with a clean block syntax
- **Zero Dependencies**: Lightweight implementation with no external runtime dependencies
- **Ruby 2.7+ Compatible**: Modern Ruby support with full type system compatibility
- **Production Ready**: Battle-tested in real-world applications

## Requirements

Ruby MRI 2.7.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'on_strum-service'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install on_strum-service
```

## Usage

### Basic Usage

```ruby
require 'on_strum/service'

class MyService
  include OnStrum::Service

  def call
    # Your service logic here
    output(result) # Use output to return successful result
  end
end

# Call with context hash
MyService.call(input_hash) do |monad|
  monad.success { |result| puts "Success: #{result}" }
  monad.failure { |errors| puts "Errors: #{errors}" }
end

# Call with only keyword arguments
MyService.call(name: 'John', age: 42) do |monad|
  monad.success { |result| puts "Success: #{result}" }
  monad.failure { |errors| puts "Errors: #{errors}" }
end

# Call with both context and keyword arguments
MyService.call(input_hash, name: 'John', age: 42) do |monad|
  monad.success { |result| puts "Success: #{result}" }
  monad.failure { |errors| puts "Errors: #{errors}" }
end
```

### Service Context and Arguments

  The service object follows a clear separation between context and service-object configuration through its calling convention:

```ruby
MyService.call(context, **config) # Please note that the context is optional and defaults to an empty hash
```

#### Context (First Argument)

The context represents the data being processed or transformed:

- Optional hash that defaults to an empty hash `{}`
- Contains the primary data that the service-object will work with
- Represents the "what" of the service-object operation
- Immutable snapshot of input data

```ruby
class DocumentProcessor
  include OnStrum::Service
  
  def call
    # Working with the main data context
    validate_metadata(metadata)
    process_content(content)
  end
end

# Processing a document with its data
DocumentProcessor.call({
  content: 'Some text content',
  metadata: { author: 'John', date: '2024-03-20' }
})

# Or with no context when not needed
DocumentProcessor.call # Uses default empty hash
```

#### Service-object Configuration (Keyword Arguments)

The keyword arguments represent service-object configuration and behavior modifiers:

- Optional parameters that control how the service-object operates
- Represents the "how" of the service-object operation
- Can override context values available as methods
- Used for service-object-specific options and flags

```ruby
class DocumentProcessor
  include OnStrum::Service
  
  def call
    return if skip_processing
    
    process_content(
      content,
      format: output_format,    # from config
      compress: compress_output # from config
    )
  end
end

# Configuring the processing behavior
DocumentProcessor.call(
  { content: 'Raw content' },           # Context: What to process
  output_format: :pdf,                  # Config: How to process
  compress_output: true,
  skip_processing: false
)
```

This separation provides several benefits:

- Clear distinction between data and configuration
- Easier testing by separating data concerns from behavioral configuration
- More flexible service reuse with different configurations
- Better code organization and readability

When the same key exists in both context and configuration:

- Configuration (keyword arguments) takes precedence
- This allows for easy overrides without modifying the original context
- The original context remains available via `input_snapshot`

```ruby
service = DocumentProcessor.call(
  { format: 'html' },          # Context format
  format: 'pdf'                # Config format - takes precedence
)
# Inside service:
# format => 'pdf'
# input_snapshot[:format] => 'html'
```

This design encourages:

- Clean separation of concerns
- Immutable input data
- Flexible configuration
- Clear intent in service calls

### Output Handling

The service object provides sophisticated handling of both success and failure cases with support for named handlers.

The output system features:

- Default output using single argument: `output(value)`
- Named outputs using key-value pairs: `output(:key, value)`
- Multiple outputs can be set during service execution
- Specific outputs can be handled with corresponding success handlers
- The last output (or default output) is returned if no specific handler matches

```ruby
class UserService
  include OnStrum::Service

  def call
    # Case 1: Default success output
    output('Default result')  # or output(:default, 'Default result')

    # Case 2: Named success output
    output(:user, { id: 1, name: 'John' })
    
    # Case 3: Multiple named outputs
    output(:stats, { count: 42 })
    output(:status, 'completed')

    # Error cases
    add_error(:validation, :invalid_format)  # Will trigger failure(:validation) handler
    add_error(:auth, :unauthorized)          # Will trigger failure(:auth) handler
  end
end

# Handling different success and failure scenarios
UserService.call(data) do |monad|
  # Success handlers
  monad.success { |result| puts "Default handler: #{result}" }
  monad.success(:user) { |user| puts "User handler: #{user}" }
  monad.success(:stats) { |stats| puts "Stats handler: #{stats}" }

  # Failure handlers
  monad.failure { |errors| puts "Default error handler: #{errors}" }
  monad.failure(:validation) { |errors| puts "Validation errors: #{errors}" }
  monad.failure(:auth) { |errors| puts "Auth errors: #{errors}" }
end
```

#### Success Handler Resolution

Success handlers are resolved in the following order:

1. Looks for a handler matching the output key (`output(:key, value)`)
2. Falls back to the default handler (defined without a key) if no specific handler is found
3. Returns the raw output value if no handlers are defined

```ruby
service.call do |monad|
  # These can be defined in any order
  monad.success(:specific) { |value| puts "Specific: #{value}" }
  monad.success { |value| puts "Default: #{value}" }
end
```

#### Failure Handler Resolution

Failure handlers are resolved based on error keys:

1. Looks for a handler matching the error key (`add_error(:key, :error)`)
2. Falls back to the default handler if no specific handler matches
3. Returns the raw errors hash if no handlers are defined

```ruby
service.call do |monad|
  # These can be defined in any order
  monad.failure(:not_found) { |errors| puts "Not found: #{errors}" }
  monad.failure(:validation) { |errors| puts "Validation: #{errors}" }
  monad.failure { |errors| puts "Default error: #{errors}" }
end
```

#### Multiple Outputs

You can set multiple outputs during service execution:

```ruby
class ProcessingService
  include OnStrum::Service

  def call
    # Set multiple outputs
    output(:step1, "First step done")
    output(:step2, "Second step done")
    output(:final, "All completed")

    # The last output becomes the default result
    # unless a specific handler is matched
  end
end

ProcessingService.call do |monad|
  monad.success(:step1) { |result| puts "Step 1: #{result}" }
  monad.success(:step2) { |result| puts "Step 2: #{result}" }
  monad.success(:final) { |result| puts "Final: #{result}" }
  monad.success { |result| puts "Default: #{result}" } # Gets :final result
end
```

#### Handler Order Independence

The order in which you define success and failure handlers doesn't matter:

- For success: The handler matching the output key will be called
- For failures: The handler matching the error key will be called
- Default handlers (without keys) serve as fallbacks

This allows for flexible and maintainable code organization while handling complex service results.

### Error Handling

```ruby
class ValidationService
  include OnStrum::Service
  
  def call
    # Add single error
    add_error(:email, :invalid)

    # Add multiple errors for one key
    add_error(:password, :too_short)
    add_error(:password, :no_special_chars)

    # Add multiple errors at once
    # You can use bang (!) methods to immediately exit the service with errors
    add_errors!(
      email: %i[invalid taken],
      password: %i[too_short no_special_chars]
    )
  end
end
```

### Required Fields Validation

```ruby
class UserService
  include OnStrum::Service

  def call
    # Validate required fields
    required!(:email)    # Will exit immediately if email is missing
    required(:password)  # Will add error but continue execution

    # Your logic here
  end

  # Also you can use audit method for prevalidations
  def audit
    required(:email)
    required(:password)
    # something else...
  end
end
```

### Hooks

```ruby
class ProcessingService
  include OnStrum::Service

  def call
    # Trigger hooks during processing
    hook(:processing_started)
    # ... do work ...
    hook(:processing_completed, result)
    output(result)
  end
end

# Handle hooks in the caller
ProcessingService.call(data) do |monad|
  monad.on(:processing_started) { puts 'Started!' }
  monad.on(:processing_completed) { |data| puts "Completed with: #{data}" }
  monad.success { |value| puts "Final result: #{value}" }
end
```

### Helper Methods

```ruby
class DataService
  include OnStrum::Service

  def call
    # Slice specific keys from input
    sliced(:name, :email)  # Reduces input to only these keys

    # Check if any of specified keys exist
    any(:email, :phone)    # Ensures at least one exists

    # Process array of hashes
    sliced_list(:name, :email) # Slices each hash in array
  end
end

# Example of error handling with sliced_list
class ArrayProcessor
  include OnStrum::Service

  def call
    # This will fail if input is not an array
    sliced_list(:name, :email)
    output(input)
  end
end

# This will fail because input is not an array
ArrayProcessor.call({ some: 'hash' }) do |monad|
  monad.failure do |errors|
    errors # => { input: [:must_be_array] }
  end
end

# This will fail because one of items is not a hash
ArrayProcessor.call([{ name: 'John' }, 'not a hash']) do |monad|
  monad.failure do |errors|
    errors # => { input_subitem: [:must_be_hash] }
  end
end

# This will succeed and process only specified keys
ArrayProcessor.call([
  { name: 'John', email: 'john@example.com', age: 30 },
  { name: 'Jane', email: 'jane@example.com', phone: '123' }
]) do |monad|
  monad.success do |processed_array|
    processed_array # => [
      # Only name and email keys are preserved
      { name: 'John', email: 'john@example.com' },
      { name: 'Jane', email: 'jane@example.com' }
    ]
  end
end
```

### Method Missing Support

The service automatically handles method missing to allow direct access to both input hash values and keyword arguments:

```ruby
class GreetingService
  include OnStrum::Service

  def call
    # 'name' will be looked up from:
    # 1. Input hash (if it's a Hash)
    # 2. Keyword arguments
    # Supports both string and symbol keys
    output("Hello, #{name}!")
  end
end

# Using input hash (context)
GreetingService.call({ name: 'John' })

# Using keyword arguments (config)
GreetingService.call({}, name: 'John')

# Mixed usage (keyword args take precedence)
GreetingService.call({ name: 'John' }, name: 'Jane')  # Will use 'Jane'

# Supports both string and symbol keys
GreetingService.call({ 'name' => 'John' })  # Works, passing context as hash with string key
GreetingService.call('name' => 'John')      # Works, passing keyword arguments with string key
GreetingService.call({ name: 'John' })      # Works, passing context as hash with symbol key
GreetingService.call(name: 'John')          # Works, passing keyword arguments with symbol key
```

The method missing implementation provides a flexible way to access input parameters:

- Checks both string and symbol versions of the key
- Looks up values in both the input hash and keyword arguments
- Uses a default proc to handle string/symbol key interchangeability
- Returns `nil` for non-existent keys instead of raising method missing errors

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/on-strum/ruby-on-strum-service>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct. Please check the [open tickets](https://github.com/on-strum/ruby-on-strum-service/issues). Be sure to follow Contributor Code of Conduct below and our [Contributing Guidelines](CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `on_strum-service` project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Credits

- [The Contributors](https://github.com/on-strum/ruby-on-strum-service/graphs/contributors) for code and awesome suggestions
- [The Stargazers](https://github.com/on-strum/ruby-on-strum-service/stargazers) for showing their support

## Versioning

`on_strum-service` uses [Semantic Versioning 2.0.0](https://semver.org)
