# frozen_string_literal: true

module Api
  module V1
    class MarketplaceItemsController < ApiController
      def index
        ransack_params = {}
        ransack_params[:chatbot_name_cont] = params[:chatbot_name] if params[:chatbot_name].present?

        @marketplace_items = MarketplaceItem.ransack(ransack_params).result(distinct: true).page(params[:page])

        render json: { success: true, marketplace_items: @marketplace_items, meta: pagination_meta(@marketplace_items) },
               status: :ok
      rescue StandardError => e
        render json: { success: false, error: e }, status: :bad_request
      end

      def show
        @marketplace_item = MarketplaceItem.find(params[:id])
        Apartment::Tenant.switch!(@marketplace_item.entity_name)
        @chatbot_detail = Chatbot.find_by(id: @marketplace_item.chatbot_id)
        render json: { success: true, marketplace_item: @marketplace_item, chatbot_detail: @chatbot_detail },
               status: :ok
      end

      def general_users_purchase
        marketplace_item = MarketplaceItem.find(params[:id])
        custom_name = params[:custom_name].presence || marketplace_item.chatbot_name
        custom_description = params[:custom_description].presence || marketplace_item.chatbot_description
        user = current_general_user

        if marketplace_item.purchase_by(user, custom_name, custom_description)
          render json: { success: true, chatbot: marketplace_item }, status: :ok
        else
          render json: { success: false, error: 'Purchase failed' }, status: :unprocessable_entity
        end
      rescue StandardError => e
        render json: { success: false, error: e.message }, status: :internal_server_error
      end

      private

      def pagination_meta(object)
        {
          current_page: object.current_page,
          next_page: object.next_page,
          prev_page: object.prev_page,
          total_pages: object.total_pages,
          total_count: object.total_count
        }
      end
    end
  end
end
