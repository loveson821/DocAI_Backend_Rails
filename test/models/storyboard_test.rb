# frozen_string_literal: true

# == Schema Information
#
# Table name: storyboards
#
#  id          :uuid             not null, primary key
#  title       :string           not null
#  description :text
#  user_id     :uuid             not null
#  meta        :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_storyboards_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'test_helper'

class StoryboardTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
