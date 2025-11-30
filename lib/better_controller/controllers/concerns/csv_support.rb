# frozen_string_literal: true

require 'csv'

module BetterController
  module Controllers
    module Concerns
      # Provides CSV generation and download helpers for controllers
      # Included automatically when using BetterController
      module CsvSupport
        extend ActiveSupport::Concern

        # Send collection as CSV file download
        # @param collection [Array] Records to export
        # @param filename [String] Download filename (default: 'export.csv')
        # @param columns [Array<Symbol>] Columns to include (default: auto-detect)
        # @param headers [Hash] Custom header names { column: 'Header Name' }
        # @example
        #   send_csv @users, filename: 'users.csv', columns: [:id, :name, :email]
        # @example With custom headers
        #   send_csv @products,
        #     filename: 'products.csv',
        #     columns: [:id, :name, :price],
        #     headers: { id: 'ID', name: 'Product Name', price: 'Price (€)' }
        def send_csv(collection, filename: 'export.csv', columns: nil, headers: {})
          csv_data = generate_csv(collection, columns: columns, headers: headers)

          send_data csv_data,
                    type: 'text/csv; charset=utf-8',
                    disposition: "attachment; filename=\"#{filename}\""
        end

        # Generate CSV string from collection
        # @param collection [Array] Records to export
        # @param columns [Array<Symbol>] Columns to include (default: auto-detect)
        # @param headers [Hash] Custom header names { column: 'Header Name' }
        # @return [String] CSV data
        # @example
        #   csv_string = generate_csv(@users, columns: [:id, :name])
        def generate_csv(collection, columns: nil, headers: {})
          return '' if collection.blank?

          # Auto-detect columns from first record if not specified
          sample = collection.first
          columns ||= detect_csv_columns(sample)

          CSV.generate do |csv|
            # Header row
            csv << columns.map { |col| headers[col] || col.to_s.humanize }

            # Data rows
            collection.each do |record|
              csv << columns.map { |col| extract_csv_value(record, col) }
            end
          end
        end

        private

        # Detect columns from a record
        # @param record [Object] Sample record
        # @return [Array<Symbol>] Column names
        def detect_csv_columns(record)
          if record.respond_to?(:attributes)
            # ActiveRecord model
            record.attributes.keys.map(&:to_sym)
          elsif record.respond_to?(:to_h)
            # Hash-like object
            record.to_h.keys.map(&:to_sym)
          else
            []
          end
        end

        # Extract value from record for given column
        # @param record [Object] Record to extract from
        # @param column [Symbol] Column name
        # @return [Object] Column value
        def extract_csv_value(record, column)
          value = if record.respond_to?(column)
                    record.public_send(column)
                  elsif record.respond_to?(:[])
                    record[column] || record[column.to_s]
                  end

          # Format special types
          format_csv_value(value)
        end

        # Format value for CSV output
        # @param value [Object] Value to format
        # @return [String, Object] Formatted value
        def format_csv_value(value)
          case value
          when Time, DateTime
            value.strftime('%Y-%m-%d %H:%M:%S')
          when Date
            value.strftime('%Y-%m-%d')
          when Array
            value.join(', ')
          when Hash
            value.to_json
          else
            value
          end
        end
      end
    end
  end
end
