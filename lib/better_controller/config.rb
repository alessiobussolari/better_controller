# frozen_string_literal: true

module BetterController
  # Config wrapper for page/component configurations
  #
  # Provides a standardized way to handle page/component configurations.
  # Supports hash-like access, destructuring, and component iteration.
  # Compatible with BetterPage::Config interface.
  #
  # @example Creating a config
  #   config = BetterController::Config.new(
  #     { header: { title: "Users" }, table: { items: users } },
  #     meta: { page_type: :index }
  #   )
  #
  # @example Hash-like access
  #   config[:header]              # => { title: "Users" }
  #   config.dig(:header, :title)  # => "Users"
  #
  # @example Destructuring
  #   components, meta = config
  #
  # @example Direct component access
  #   config.header[:title]  # => "Users"
  #
  class Config
    attr_reader :components, :meta

    # @param components [Hash] Component configurations
    # @param meta [Hash] Metadata (page_type, klass, etc.)
    def initialize(components, meta: {})
      @components = components.is_a?(Hash) ? components : {}
      @meta = meta.is_a?(Hash) ? meta : {}
    end

    # Support destructuring: components, meta = config
    # @return [Array] Array with components and meta
    def to_ary
      [components, meta]
    end

    # Hash-like access for compatibility
    # @param key [Symbol] The key to access
    # @return [Object, nil] The value
    def [](key)
      to_h[key]
    end

    # Deep access for nested values
    # @param keys [Array<Symbol>] Keys to dig into
    # @return [Object, nil] The value at the nested key path
    def dig(*keys)
      to_h.dig(*keys)
    end

    # Convert to hash for compatibility
    # @return [Hash] Hash representation
    def to_h
      {
        components: components,
        meta: meta,
        page_type: meta[:page_type],
        klass: meta[:klass]
      }.merge(components).compact
    end

    # Direct accessor for components via method_missing
    # @param name [Symbol] Component name
    # @return [Hash, nil] Component configuration
    def method_missing(name, *args, &block)
      return components[name] if components.key?(name)

      super
    end

    # @param name [Symbol] Method name
    # @param include_private [Boolean] Include private methods
    # @return [Boolean] Whether method is handled
    def respond_to_missing?(name, include_private = false)
      components.key?(name) || super
    end

    # Check if a component is defined and present
    # @param name [Symbol] Component name
    # @return [Boolean]
    def component?(name)
      components.key?(name) && components[name].present?
    end

    # List of component names
    # @return [Array<Symbol>]
    def component_names
      components.keys
    end

    # Iterate over components
    # @yield [name, config] Component name and configuration
    def each_component(&block)
      components.each(&block)
    end

    # Components with present values only
    # @return [Hash]
    def present_components
      components.select { |_, v| v.present? }
    end

    # Page type from meta
    # @return [Symbol, nil]
    def page_type
      meta[:page_type]
    end

    # ViewComponent class from meta
    # @return [Class, nil]
    def klass
      meta[:klass]
    end
  end
end
