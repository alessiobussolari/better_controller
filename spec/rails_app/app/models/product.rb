# frozen_string_literal: true

class Product < ActiveRecord::Base
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :in_stock, -> { where('stock_quantity > 0') }
end
