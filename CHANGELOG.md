# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-08-27

### Added
- Support for external module callbacks with `@then {Module, :function}` syntax
- Comprehensive validation for callback formats with clear error messages
- Tests covering external module callbacks, mixed callback types, and error cases

## [1.0.0] - 2025-08-26

### Added
- Initial release of `Then` library
- `@then` attribute for post-execution callbacks
- Support for side-effect separation from main function logic
- Compile-time validation to prevent multiple `@then` attributes per function
- Compatibility with other function attributes (`@doc`, `@spec`, `@deprecated`)
- Support for private callback functions (`defp`)
- Comprehensive test suite
- Documentation with examples and limitations

### Features
- Clean separation of concerns between pure functions and side effects
- Automatic callback invocation after function execution
- Function result preservation (callbacks don't modify return values)
- Multi-clause function support
- Macro-based implementation for zero runtime overhead
