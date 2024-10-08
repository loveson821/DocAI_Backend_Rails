# frozen_string_literal: true

module GeneralUsers
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    private

    def respond_with(resource, _opts = {})
      resource.persisted? ? register_success : register_failed
    end

    def register_success
      render json: { success: true, message: 'Signed up.' }, status: :ok
    end

    def register_failed
      render json: { success: false, message: 'Signed up failure.' }, status: :unauthorized
    end
  end
end
