# frozen_string_literal: true

# Mock helper for Turbo Stream that generates HTML without requiring turbo-rails gem.
# This mimics the turbo_stream helper from turbo-rails for testing purposes.
module TurboStreamHelper
  # Builder class that generates Turbo Stream HTML tags
  class TurboStreamBuilder
    def replace(target, content = nil, &block)
      build_stream(:replace, target, content, &block)
    end

    def update(target, content = nil, &block)
      build_stream(:update, target, content, &block)
    end

    def append(target, content = nil, &block)
      build_stream(:append, target, content, &block)
    end

    def prepend(target, content = nil, &block)
      build_stream(:prepend, target, content, &block)
    end

    def remove(target)
      %(<turbo-stream action="remove" target="#{target}"></turbo-stream>).html_safe
    end

    def refresh
      %(<turbo-stream action="refresh"></turbo-stream>).html_safe
    end

    private

    def build_stream(action, target, content = nil, &block)
      inner = content || (block ? block.call : '')
      %(<turbo-stream action="#{action}" target="#{target}"><template>#{inner}</template></turbo-stream>).html_safe
    end
  end

  # Returns a Turbo Stream builder instance
  # @return [TurboStreamBuilder] Builder for generating turbo stream tags
  def turbo_stream
    @turbo_stream_builder ||= TurboStreamBuilder.new
  end

  # Generate a turbo-frame tag
  # @param id [String, Symbol] Frame ID
  # @param src [String, nil] Optional source URL for lazy loading
  # @return [String] HTML turbo-frame tag
  def turbo_frame_tag(id, src: nil, &block)
    content = block ? block.call : ''
    src_attr = src ? %( src="#{src}") : ''
    %(<turbo-frame id="#{id}"#{src_attr}>#{content}</turbo-frame>).html_safe
  end
end
