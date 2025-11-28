# Changelog

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
