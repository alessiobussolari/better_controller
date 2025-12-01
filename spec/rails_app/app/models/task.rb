# frozen_string_literal: true

class Task < ActiveRecord::Base
  STATUSES = %w[pending in_progress completed cancelled].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }

  def complete!
    update!(status: 'completed')
  end

  def cancel!
    update!(status: 'cancelled')
  end
end
