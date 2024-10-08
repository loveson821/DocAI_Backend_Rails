# frozen_string_literal: true

# == Schema Information
#
# Table name: folders
#
#  id         :uuid             not null, primary key
#  name       :string           default("New Folder"), not null
#  parent_id  :uuid
#  user_id    :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folders_on_parent_id  (parent_id)
#  index_folders_on_parent_id  (parent_id)
#  index_folders_on_user_id    (user_id)
#  index_folders_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (user_id => public.users.id)
#
class Folder < ApplicationRecord
  resourcify
  acts_as_tree dependent: :destroy

  belongs_to :user, class_name: 'User', foreign_key: 'user_id', optional: true
  has_one :project, class_name: 'Project', foreign_key: 'folder_id'
  has_one :project_workflow, class_name: 'ProjectWorkflow', foreign_key: 'folder_id'
  has_many :documents, dependent: :destroy, class_name: 'Document', foreign_key: 'folder_id'
  has_many :folders, dependent: :destroy, class_name: 'Folder', foreign_key: 'parent_id'
  has_many :mini_apps, dependent: :destroy, class_name: 'MiniApp', foreign_key: 'folder_id'

  after_create :set_permissions_to_owner
  before_destroy :unlink_from_chatbots

  paginates_per 20
  has_paper_trail

  def set_permissions_to_owner
    return if self['user_id'].nil?

    user.add_role :r, self

    user.add_role :w, self
  end

  def share_with(other)
    # if user has permission to share folder, then add role to other user
    return unless user.has_role? :w, self

    other.add_role :r, self

    other.add_role :w, self
  end

  # def set_sub_folder(sf)
  #   sf.update(ancestry: self['id'])
  # end

  def has_rights_to_read?(user)
    return true if user_id.nil?

    user.has_role? :r, self
  end

  def has_rights_to_write?(user)
    return true if user_id.nil?

    user.has_role? :w, self
  end

  def allow_user_access?(user)
    # 睇下呢個 folder 的 parent folders 會唔會有權限
    folder_ids = ancestors.pluck(:id)
    user.roles.includes(:roles).where(resource_type: 'Folder', resource_id: folder_ids, name: 'r').exists?
  end

  private

  def unlink_from_chatbots
    Chatbot.all.find_each do |chatbot|
      if chatbot.source['folder_id'].is_a?(Array) && chatbot.source['folder_id'].include?(id.to_s)
        chatbot.source['folder_id'].delete(id.to_s)
        chatbot.save
      end
    end
  end
end
