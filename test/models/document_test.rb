# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id                    :uuid             not null, primary key
#  name                  :string
#  storage_url           :string
#  content               :text
#  status                :integer          default("pending"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  approval_status       :integer          default("awaiting"), not null
#  approval_user_id      :uuid
#  approval_at           :datetime
#  folder_id             :uuid
#  upload_local_path     :string
#  user_id               :uuid
#  is_classified         :boolean          default(FALSE)
#  is_document           :boolean          default(TRUE)
#  meta                  :jsonb
#  is_classifier_trained :boolean          default(FALSE)
#  is_embedded           :boolean          default(FALSE)
#  error_message         :text
#  retry_count           :integer          default(0)
#
require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
