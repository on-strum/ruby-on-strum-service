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

# Recommended approach - inheritance
class MyService < OnStrum::Service
  def call
    # Your service logic here
    output(result) # Use output to return successful result
  end
end

# Alternative approach using include (not recommended)
class AnotherService
  include OnStrum::Service

  def call
    # Your service logic here
    output(result)
  end
end

# Call the service
MyService.call(input_hash) do |result|
  result.success { |value| puts "Success: #{value}" }
  result.failure { |errors| puts "Errors: #{errors}" }
end
```

> [!IMPORTANT]  
> While it's possible to use the service module through inclusion (`include OnStrum::Service`), we strongly recommend using inheritance (`< OnStrum::Service`) for better code clarity and maintainability. This approach provides a clearer indication of the service object pattern implementation and makes the code more explicit.

### Error Handling

```ruby
class ValidationService < OnStrum::Service
  def call
    # Add single error
    add_error(:email, :invalid)

    # Add multiple errors for one key
    add_error(:password, :too_short)
    add_error(:password, :no_special_chars)

    # Add multiple errors at once
    # You can use bang (!) methods to immediately exit the service with errors
    add_errors!(
      email: [:invalid, :taken],
      password: [:too_short]
    )
  end
end
```

### Required Fields Validation

```ruby
class UserService < OnStrum::Service
  def call
    # Validate required fields
    required!(:email)    # Will exit immediately if email is missing
    required(:password)  # Will add error but continue execution

    # Your logic here
  end

  # You can also use audit method for validations
  def audit
    required(:email)
    required(:password)
  end
end
```

### Hooks

```ruby
class ProcessingService < OnStrum::Service
  def call
    # Trigger hooks during processing
    hook(:processing_started)
    # ... do work ...
    hook(:processing_completed, result)
    output(result)
  end
end

# Handle hooks in the caller
ProcessingService.call(data) do |result|
  result.on(:processing_started) { puts 'Started!' }
  result.on(:processing_completed) { |data| puts "Completed with: #{data}" }
  result.success { |value| puts "Final result: #{value}" }
end
```

### Helper Methods

```ruby
class DataService < OnStrum::Service
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
class ArrayProcessor < OnStrum::Service
  def call
    # This will fail if input is not an array
    sliced_list(:name, :email)
    output(input)
  end
end

# This will fail because input is not an array
ArrayProcessor.call({ some: 'hash' }) do |result|
  result.failure do |errors|
    errors # => { input: [:must_be_array] }
  end
end

# This will fail because one of items is not a hash
ArrayProcessor.call([{ name: 'John' }, 'not a hash']) do |result|
  result.failure do |errors|
    errors # => { input_subitem: [:must_be_hash] }
  end
end

# This will succeed and process only specified keys
ArrayProcessor.call([
  { name: 'John', email: 'john@example.com', age: 30 },
  { name: 'Jane', email: 'jane@example.com', phone: '123' }
]) do |result|
  result.success do |processed_array|
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
class GreetingService < OnStrum::Service
  def call
    # 'name' will be looked up from:
    # 1. Input hash (if it's a Hash)
    # 2. Keyword arguments
    # Supports both string and symbol keys
    output("Hello, #{name}!")
  end
end

# Using input hash
GreetingService.call({ name: 'John' })

# Using keyword arguments
GreetingService.call({}, name: 'John')

# Mixed usage (keyword args take precedence)
GreetingService.call({ name: 'John' }, name: 'Jane')  # Will use 'Jane'

# Supports both string and symbol keys
GreetingService.call({ 'name' => 'John' })  # Works
GreetingService.call({ :name => 'John' })   # Works too
```

The method missing implementation provides a flexible way to access input parameters:

- Checks both string and symbol versions of the key
- Looks up values in both the input hash and keyword arguments
- Uses a default proc to handle string/symbol key interchangeability
- Returns `nil` for non-existent keys instead of raising method missing errors

### Output Handling

The service provides flexible output handling through the `output` method:

```ruby
class UserService < OnStrum::Service
  def call
    # Basic usage - single output
    output(user)  # Same as output(:default, user)

    # Named outputs
    output(:user, user)
    output(:stats, stats)

    # Last output is returned by default
    output(:final_result, "Done!")
  end
end

# Handle different outputs in the caller
UserService.call(data) do |result|
  # Handle default output
  result.success { |value| puts "Default: #{value}" }

  # Handle specific named output
  result.success(:user) { |user| puts "User: #{user}" }
  result.success(:stats) { |stats| puts "Stats: #{stats}" }

  # Handle failures
  result.failure { |errors| puts "Errors: #{errors}" }
end
```

The output system features:

- Default output using single argument: `output(value)`
- Named outputs using key-value pairs: `output(:key, value)`
- Multiple outputs can be set during service execution
- Specific outputs can be handled with corresponding success handlers
- The last output (or default output) is returned if no specific handler matches

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
