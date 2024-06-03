# == Schema Information
#
# Table name: links
#
#  id          :bigint(8)        not null, primary key
#  title       :string
#  url         :string
#  link_set_id :bigint(8)        not null
#  meta        :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_links_on_link_set_id  (link_set_id)
#
# Foreign Keys
#
#  fk_rails_...  (link_set_id => link_sets.id)
#
# app/models/link.rb
class Link < ApplicationRecord

  store_accessor :meta, :is_required_time_limit, :time_limit

  belongs_to :link_set
  validates :url, presence: true, format: { with: URI::regexp(%w[http https]) }
  validates :title, presence: true

  before_create :generate_slug
  
  def to_param
    slug
  end

  def generate_slug
    self.slug ||= generate_unique_slug
  end

  def generate_unique_slug
    loop do
      slug = SecureRandom.urlsafe_base64(6)
      break slug unless Link.exists?(slug: slug)
    end
  end

end
