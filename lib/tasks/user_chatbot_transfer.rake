# frozen_string_literal: true

namespace :user_chatbot_transfer do
  task add_system_assistant_for_all_users: :environment do
    puts 'add_system_assistant_for_all_users'
    Apartment::Tenant.each do |tenant|
      Apartment::Tenant.switch!(tenant)
      puts "====== tenant: #{tenant} ======"
      @users = User.all
      @users.each do |user|
        next if user.system_assistant.present?

        user.system_assistant = Chatbot.create(
          name: "#{user.email}'s assistant",
          user_id: user.id,
          object_type: 'UserSystemAssistant',
          object_id: user.id,
          source: { folder_id: [''] }
        )
        puts "====== #{user.email}'s assistant created ======"
      end
    end
  end
end
