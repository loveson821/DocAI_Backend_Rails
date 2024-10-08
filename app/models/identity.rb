# frozen_string_literal: true

# == Schema Information
#
# Table name: identities
#
#  id         :uuid             not null, primary key
#  user_id    :uuid             not null
#  provider   :string
#  uid        :string
#  meta       :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_identities_on_provider  (provider)
#  index_identities_on_provider  (provider)
#  index_identities_on_user_id   (user_id)
#  index_identities_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (user_id => public.users.id)
#
class Identity < ApplicationRecord
  filterrific(
    default_filter_params: { sorted_by: 'created_at_desc' },
    available_filters: %i[
      sorted_by
      search_query
    ]
  )
  belongs_to :user, optional: true

  validates_presence_of :uid, :provider
  validates_uniqueness_of :uid, scope: :provider

  def self.find_for_oauth(auth)
    puts auth['uid']
    puts auth['provider']
    puts '-----------------'
    find_or_create_by(uid: auth['uid'], provider: auth['provider'])
  end
end
