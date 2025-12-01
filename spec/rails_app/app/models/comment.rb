# frozen_string_literal: true

class Comment < ActiveRecord::Base
  belongs_to :article

  validates :body, presence: true
  validates :author, presence: true
end
