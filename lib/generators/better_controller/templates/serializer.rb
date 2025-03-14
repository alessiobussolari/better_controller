# frozen_string_literal: true

class <%= serializer_class_name %> < BetterController::Serializer
  # Define the attributes to include in the serialized output
  attributes :id, 
             :created_at, 
             :updated_at
             # Add your model attributes here
  
  # Define methods to include in the serialized output
  # methods :calculated_field
  
  # Define associations to include in the serialized output
  # has_many :related_items
  # has_one :related_item
  # belongs_to :parent_item
  
  # Optional: Define a custom serializer for a specific association
  # has_many :related_items, serializer: RelatedItemSerializer
  
  # Optional: Define a method that returns a calculated field
  # def calculated_field
  #   # Add your calculation logic here
  #   object.some_attribute * 2
  # end
  
  # Optional: Define a method that conditionally includes an attribute
  # def include_some_attribute?
  #   # Add your condition logic here
  #   object.some_condition?
  # end
end
