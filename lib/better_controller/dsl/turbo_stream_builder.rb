# frozen_string_literal: true

module BetterController
  module Dsl
    # Builder for Turbo Stream responses
    # Provides a DSL to define multiple stream actions
    class TurboStreamBuilder
      attr_reader :streams

      def initialize
        @streams = []
      end

      # Append content to a target element
      # @param target [Symbol, String, Object] Target element ID or object with dom_id
      # @param component [Class] Optional ViewComponent class
      # @param partial [String] Optional partial path
      # @param locals [Hash] Local variables for partial
      def append(target, component: nil, partial: nil, locals: {})
        @streams << {
          action: :append,
          target: target,
          component: component,
          partial: partial,
          locals: locals
        }
      end

      # Prepend content to a target element
      # @param target [Symbol, String, Object] Target element ID or object with dom_id
      # @param component [Class] Optional ViewComponent class
      # @param partial [String] Optional partial path
      # @param locals [Hash] Local variables for partial
      def prepend(target, component: nil, partial: nil, locals: {})
        @streams << {
          action: :prepend,
          target: target,
          component: component,
          partial: partial,
          locals: locals
        }
      end

      # Replace a target element
      # @param target [Symbol, String, Object] Target element ID or object with dom_id
      # @param component [Class] Optional ViewComponent class
      # @param partial [String] Optional partial path
      # @param locals [Hash] Local variables for partial
      def replace(target, component: nil, partial: nil, locals: {})
        @streams << {
          action: :replace,
          target: target,
          component: component,
          partial: partial,
          locals: locals
        }
      end

      # Update the content of a target element
      # @param target [Symbol, String, Object] Target element ID or object with dom_id
      # @param component [Class] Optional ViewComponent class
      # @param partial [String] Optional partial path
      # @param locals [Hash] Local variables for partial
      def update(target, component: nil, partial: nil, locals: {})
        @streams << {
          action: :update,
          target: target,
          component: component,
          partial: partial,
          locals: locals
        }
      end

      # Remove a target element
      # @param target [Symbol, String, Object] Target element ID or object with dom_id
      def remove(target)
        @streams << {
          action: :remove,
          target: target
        }
      end

      # Add content before a target element
      # @param target [Symbol, String, Object] Target element ID or object with dom_id
      # @param component [Class] Optional ViewComponent class
      # @param partial [String] Optional partial path
      # @param locals [Hash] Local variables for partial
      def before(target, component: nil, partial: nil, locals: {})
        @streams << {
          action: :before,
          target: target,
          component: component,
          partial: partial,
          locals: locals
        }
      end

      # Add content after a target element
      # @param target [Symbol, String, Object] Target element ID or object with dom_id
      # @param component [Class] Optional ViewComponent class
      # @param partial [String] Optional partial path
      # @param locals [Hash] Local variables for partial
      def after(target, component: nil, partial: nil, locals: {})
        @streams << {
          action: :after,
          target: target,
          component: component,
          partial: partial,
          locals: locals
        }
      end

      # Helper: Update flash message
      # @param type [Symbol] Flash type (:notice, :alert, etc.)
      # @param message [String] Optional custom message
      def flash(type: :notice, message: nil)
        @streams << {
          action: :update,
          target: :flash,
          partial: 'shared/flash',
          locals: { type: type, message: message }
        }
      end

      # Helper: Update form errors
      # @param errors [Object] Errors object (usually ActiveModel::Errors)
      # @param target [Symbol, String] Target element ID (default: :form_errors)
      def form_errors(errors: nil, target: :form_errors)
        @streams << {
          action: :update,
          target: target,
          partial: 'shared/form_errors',
          locals: { errors: errors }
        }
      end

      # Helper: Refresh the page (Turbo 8+)
      def refresh
        @streams << { action: :refresh }
      end

      # Build the streams configuration
      # @return [Array<Hash>] Array of stream configurations
      def build
        @streams
      end
    end
  end
end
