# frozen_string_literal: true

# == Route Map
#
Rails.application.routes.draw do
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users,
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations'
             }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # **********Documents API**********
      resources :documents, only: %i[index show update destroy] do
        collection do
          get 'collection', to: 'documents#show_by_ids', as: :show_documents_by_ids
          get 'latest/predict', to: 'documents#show_latest_predict'
          get ':date/predict', to: 'documents#show_specify_date_latest_predict'
          post 'deep_understanding', to: 'documents#deep_understanding'
        end

        member do
          post 'approval', to: 'documents#approval'
          get 'ocr', to: 'documents#ocr'
        end

        get 'tags/:tag_id', to: 'documents#show_by_tag', as: :show_documents_by_tag
      end

      # **********Search API**********
      # Search documents by name like name param
      get 'search/documents/name', to: 'documents#show_by_name'
      # Search documents by content like content param
      get 'search/documents/content', to: 'documents#show_by_content'
      # Search documents by date
      get 'search/documents/date', to: 'documents#show_by_date'
      # Search documents by tag and date
      get 'search/documents/tag_content', to: 'documents#show_by_tag_and_content'
      # Search form data by form schema name and date
      get 'search/form/:name/:date', to: 'form_datum#show_by_form_name_and_date'
      # Search form data by date
      get 'search/form/:date', to: 'form_datum#show_by_date'

      # **********Tags API**********
      get 'tags', to: 'tags#index'
      get 'tags/:id', to: 'tags#show'
      get 'tags/tagging/document', to: 'tags#show_by_tagging'
      get 'tags/:id/functions', to: 'tags#show_functions'
      post 'tags', to: 'tags#create'
      put 'tags/:id', to: 'tags#update'
      put 'tags/:id/features', to: 'tags#update_chain_features'
      post 'tags/function', to: 'tag_functions#create'
      delete 'tags/function', to: 'tag_functions#destroy'

      # **********Functions API**********
      get 'functions', to: 'functions#index'
      get 'functions/:id', to: 'functions#show'
      post 'functions', to: 'functions#create'
      put 'functions/:id', to: 'functions#update'

      # **********Storage API**********
      post 'storage/upload', to: 'storage#upload'
      post 'storage/upload/batch/tag', to: 'storage#upload_batch_tag'
      post 'storage/upload/directly', to: 'storage#upload_directly'
      post 'storage/upload/generated_content', to: 'storage#upload_generated_content'
      post 'storage/upload/chatbot', to: 'storage#chatbot_upload'

      # **********FormSchema API**********
      get 'form/schemas', to: 'form_schema#index'
      get 'form/schemas/:id', to: 'form_schema#show'
      get 'form/schemas/name/:name', to: 'form_schema#show_by_name'
      get 'form/schemas/status/ready', to: 'form_schema#show_ready'
      get 'form/schemas/status/project', to: 'form_schema#show_can_project'

      # **********FormDatum API**********
      get 'form/datum', to: 'form_datum#index'
      get 'form/datum/:id', to: 'form_datum#show'
      post 'form/datum/:form_schema_id/search', to: 'form_datum#show_by_filter_and_form_schema_id'
      put 'form/datum/:id', to: 'form_datum#update'
      delete 'form/datum/:id', to: 'form_datum#destroy'
      post 'form/datum/generate/chart', to: 'form_datum#generate_chart'

      # **********AbsenceForm API**********
      get 'form/absence/approval', to: 'absence_forms#show_by_approval_status'
      get 'form/absence/approval/:id', to: 'absence_forms#show_by_approval_id'
      post 'form/absence', to: 'absence_forms#upload'
      put 'form/absence/:id', to: 'absence_forms#update'
      get 'form/absence/recognition/:id', to: 'absence_forms#recognize_specific'

      # **********Classification API**********
      get 'classification/predict', to: 'classifications#predict'
      post 'classification/confirm', to: 'classifications#confirm'
      put 'classification', to: 'classifications#update_classification'

      # **********Statistics API**********
      get 'statistics/count/tags/:date', to: 'statistics#count_each_tags_by_date'
      get 'statistics/count/documents/:date', to: 'statistics#count_document_by_date'
      get 'statistics/count/documents/status/:date', to: 'statistics#count_document_status_by_date'

      # **********Document Approval API**********
      get 'approval/documents', to: 'document_approvals#index'
      get 'approval/documents/:id', to: 'document_approvals#show'
      get 'approval/normal/documents', to: 'document_approvals#show_normal_documents_by_approval_status'
      get 'approval/form/documents', to: 'document_approvals#show_forms_by_approval_status'
      put 'approval/documents/:id', to: 'document_approvals#update'

      # **********Folder API**********
      get 'folders', to: 'folders#index'
      get 'folders/:id', to: 'folders#show'
      get 'folders/:id/ancestors', to: 'folders#show_ancestors'
      post 'folders', to: 'folders#create'
      put 'folders/:id', to: 'folders#update'
      delete 'folders/:id', to: 'folders#destroy'
      post 'folders/documents', to: 'folders#add_document'

      # **********Drive API**********
      get 'drive/files', to: 'drive#index'
      get 'drive/files/:id', to: 'drive#show'
      post 'drive/folders/share', to: 'drive#share'
      post 'drive/items/move', to: 'drive#move_items'

      # **********Form API**********
      post 'form/recognition', to: 'forms#recognize'

      # **********Project API**********
      get 'projects', to: 'projects#index'
      get 'projects/:id', to: 'projects#show'
      get 'projects/:id/tasks', to: 'projects#show_tasks'
      post 'projects', to: 'projects#create'
      put 'projects/:id', to: 'projects#update'
      delete 'projects/:id', to: 'projects#destroy'

      # **********Project Tasks API**********
      get 'tasks', to: 'project_tasks#index'
      get 'tasks/:id', to: 'project_tasks#show'
      post 'tasks', to: 'project_tasks#create'
      put 'tasks/:id', to: 'project_tasks#update'
      delete 'tasks/:id', to: 'project_tasks#destroy'

      # **********User API**********
      get 'users/:id/profile', to: 'users#show'
      get 'users/me', to: 'users#show_current_user'
      put 'users/me/password', to: 'users#update_password'
      put 'users/me/profile', to: 'users#update_profile'

      # **********Form Projection API**********
      post 'form/projection/preview', to: 'form_projection#preview'
      post 'form/projection/confirm', to: 'form_projection#confirm'

      # **********OpenAI API**********
      post 'ai/query', to: 'open_ai#query'
      post 'ai/query/documents', to: 'open_ai#query_documents'

      # **********Mini App API**********
      resources :mini_apps, only: %i[index show create update destroy] do
      end

      # **********Chatbot API**********
      resources :chatbots, only: %i[index show create update destroy] do
        collection do
          post 'assistant/message', to: 'chatbots#assistantQA'
          post 'assistant/suggestion', to: 'chatbots#assistantQASuggestion'
        end
      end

      # **********Tool API**********
      post 'tools/upload_directly_ocr', to: 'tools#upload_directly_ocr'
      post 'tools/text_to_pdf', to: 'tools#text_to_pdf'

      # **********Smart Extraction Schema API**********
      resources :smart_extraction_schemas, only: %i[index show create update destroy] do
        collection do
          get '/:id/data', to: 'smart_extraction_schemas#show_document_extracted_data'
          get '/label/:label_id', to: 'smart_extraction_schemas#show_by_label_id'
        end
      end
    end

    namespace :schema do
      namespace :v1 do
        # **********Chatbot API**********
        resources :chatbots, only: %i[index show create update destroy] do
          collection do
            post 'assistant/message', to: 'chatbots#assistantQA'
            post 'assistant/suggestion', to: 'chatbots#assistantQASuggestion'
          end
        end
      end
    end
  end
end
