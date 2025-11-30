# frozen_string_literal: true

# Register Turbo Stream MIME type for tests
Mime::Type.register 'text/vnd.turbo-stream.html', :turbo_stream unless Mime::Type.lookup_by_extension(:turbo_stream)

# CSV is registered by default in Rails, but ensure it exists
Mime::Type.register 'text/csv', :csv unless Mime::Type.lookup_by_extension(:csv)
