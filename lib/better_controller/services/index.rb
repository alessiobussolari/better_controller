# frozen_string_literal: true

# This file serves as an index for the services directory
# It requires all files in this directory to ensure proper loading

Dir[File.join(__dir__, '*.rb')].each do |file|
  require file unless file.end_with?('index.rb')
end
