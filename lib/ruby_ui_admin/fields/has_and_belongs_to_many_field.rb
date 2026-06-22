# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class HasAndBelongsToManyField < HasManyField
      register_as :has_and_belongs_to_many
    end
  end
end
