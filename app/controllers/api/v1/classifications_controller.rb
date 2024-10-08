# frozen_string_literal: true

module Api
  module V1
    class ClassificationsController < ApiController
      # before_action :authenticate_user!

      include Authenticatable
      before_action :authenticate

      # Predict the Document
      def predict
        @document = Document.find(params[:id])
        classification_model_name = ClassificationModelVersion.where(entity_name: getSubdomain).order(created_at: :desc).first&.classification_model_name
        res = RestClient.get "#{ENV['DOCAI_ALPHA_URL']}/classification/predict?content=#{URI.encode_www_form_component(@document.content.to_s)}&model=#{classification_model_name}"
        render json: { success: true, prediction: { tag: JSON.parse(res)['label'], document: @document } }, status: :ok
      end

      # Confirm the Document
      def confirm
        @document = Document.find(params[:document_id])
        @document.label_ids = params[:tag_id]
        @document.status = :confirmed
        TagFunctionMappingService.mappping(@document.id, params[:tag_id])
        puts "Subdomain: #{getSubdomain}"
        DocumentClassificationJob.perform_async(@document.id, params[:tag_id], getSubdomain)
        documentSmartExtraction(@document.id, params[:tag_id])
        if @document.save
          render json: { success: true, document: @document }, status: :ok
        else
          render json: { success: false }, status: :unprocessable_entity
        end
      end

      # Update the Document Classification
      def update_classification
        document_ids = params[:document_ids]
        tag_id = params[:tag_id]

        puts "Document IDs: #{document_ids.inspect} Tag ID: #{tag_id.inspect}"

        Document.transaction do
          @documents = Document.where(id: document_ids).each do |document|
            document.update!(label_ids: tag_id, status: :confirmed, is_classified: true)
            TagFunctionMappingService.mappping(document.id, tag_id)
            DocumentClassificationJob.perform_async(document.id, tag_id, getSubdomain)
            documentSmartExtraction(document.id, tag_id)
          end
        end

        render json: { success: true, documents: @documents }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end

      private

      def documentSmartExtraction(document_id, label_id)
        SmartExtractionSchema.where(label_id:).where(has_label: true).each do |schema|
          DocumentSmartExtractionDatum.create(document_id:, smart_extraction_schema_id: schema.id,
                                              data: schema.data_schema)
        end
      end

      def getSubdomain
        Utils.extractRequestTenantByToken(request)
      end
    end
  end
end
