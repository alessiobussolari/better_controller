# frozen_string_literal: true

class CreateExamples < ActiveRecord::Migration[7.1]
  def change
    create_table :examples do |t|
      t.string :name
      t.string :email
      t.timestamps
    end
  end
end
