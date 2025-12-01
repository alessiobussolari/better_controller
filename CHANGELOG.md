# Changelog

## [Unreleased]

### Added
- **Turbo Frame DSL** - New explicit `turbo_frame {}` handler for Turbo Frame requests
  - `component(klass, locals: {})` - Render a ViewComponent
  - `partial(path, locals: {})` - Render a partial
  - `render_page(status: :ok)` - Render using page config
  - `layout(true/false)` - Control layout rendering (default: false)
- TurboFrameBuilder class for building Turbo Frame responses
- Fallback behavior: turbo_frame → html when no handler defined

### Changed
- Test coverage improved to 761 examples

## [0.3.0] - 2025-11-30

### Changed
- **BREAKING: Removed Services module** - BetterController no longer provides built-in services. Use your preferred service pattern (Interactor, Trailblazer, simple PORO, etc.)
- **BREAKING: Removed Serializers module** - BetterController no longer provides built-in serializers. Use your preferred serializer (ActiveModel::Serializers, Blueprinter, JBuilder, or `as_json`)
- **BREAKING: New response format** - API responses now use `{data, meta: {version}}` format instead of `{success, data, message, meta}`
- Response helpers now use `meta:` parameter instead of `options:`
- Controller generator no longer creates service or serializer files

### Added
- `api_version` configuration option (default: 'v1') - automatically included in all API responses
- ResourcesController now provides `serialize_resource` and `serialize_collection` methods that can be overridden

### Removed
- `BetterController::Services::Service` base class
- `BetterController::Serializers::Serializer` module
- Service generator template
- Serializer generator template
- `--skip-service` and `--skip-serializer` generator options

### Fixed
- Simplified ResourcesController to work directly with ActiveRecord models
- Test coverage improved to 98%+ with 587 examples

## [0.2.0] - 2025-03-14

### Added
- **Declarative Action DSL** - Define controller actions with `action :name do ... end`
- **Turbo Support** - Built-in Turbo Frames and Turbo Streams integration
- **ViewComponent Integration** - Seamless rendering with page_config
- **BetterControllerApi module** - Simplified JSON API controllers with `include BetterControllerApi`
- **BetterController shortcut** - HTML controllers with `include BetterController`
- **DSL Builders** - ActionBuilder, ResponseBuilder, TurboStreamBuilder for declarative definitions
- **Rendering System** - PageConfigRenderer and ComponentRenderer for flexible view handling
- **Context7 Documentation** - LLM-optimized docs in `context7/`
- Comprehensive API response documentation in `docs/api_responses.md`
- Detailed serializer usage guide in `docs/serializers.md`
- Enhanced README with complete Action DSL reference
- Test coverage improved to 75%+ with 444 examples

### Fixed
- Fixed serializer bug when handling nil values
- Improved serialization of both single resources and collections
- Enhanced test coverage for serializers

## [0.1.0] - 2025-03-13

### Added
- ResourcesController module for standardized RESTful resource functionality
- Service class for handling resource operations
- Serializer module for standardized resource serialization
- Pagination module for ActiveRecord collections
- ParamsHelpers module for enhanced parameter handling
- Logging module for enhanced logging capabilities
- Configuration module for global configuration
- Rails generators for controllers, services, and serializers
- Rails integration via Railtie
- Method not overridden error handling
- Comprehensive documentation and examples
