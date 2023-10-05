# == Schema Information
#
# Table name: messages
#
#  id          :uuid             not null, primary key
#  chatbot_id  :uuid             not null
#  content     :text             not null
#  role        :string           default("user"), not null
#  user_id     :uuid
#  object_type :string           not null
#  is_read     :boolean          default(FALSE), not null
#  meta        :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
