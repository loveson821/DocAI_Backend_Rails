# frozen_string_literal: true

# == Schema Information
#
# Table name: public.assessment_records
#
#  id              :uuid             not null, primary key
#  title           :string
#  record          :jsonb
#  meta            :jsonb
#  recordable_type :string
#  recordable_id   :uuid
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  score           :decimal(, )      default(0.0), not null
#  questions_count :integer          default(0), not null
#  full_score      :decimal(, )      default(0.0), not null
#
# Indexes
#
#  index_assessment_records_on_recordable  (recordable_type,recordable_id)
#
require 'test_helper'

class AssessmentRecordTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
