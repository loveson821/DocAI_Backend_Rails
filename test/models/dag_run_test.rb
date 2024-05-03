# frozen_string_literal: true

# == Schema Information
#
# Table name: dag_runs
#
#  id               :uuid             not null, primary key
#  user_id          :uuid
#  dag_name         :string
#  dag_status       :integer          default("pending"), not null
#  meta             :jsonb
#  statistic        :jsonb
#  dag_meta         :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  airflow_accepted :boolean          default(FALSE), not null
#  tanent           :string
#  user_type        :string           default("User"), not null
#
# Indexes
#
#  index_dag_runs_on_airflow_accepted  (airflow_accepted)
#  index_dag_runs_on_dag_status        (dag_status)
#  index_dag_runs_on_tanent            (tanent)
#  index_dag_runs_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'test_helper'

class DagRunTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
