# frozen_string_literal: true

class Example < ActiveRecord::Base
  validates :name, presence: true

  # Used for testing destroy errors
  attr_accessor :prevent_destruction

  before_destroy do
    if prevent_destruction
      errors.add(:base, 'Cannot destroy this example')
      throw(:abort)
    end
  end
end
