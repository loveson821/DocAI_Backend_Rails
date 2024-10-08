# frozen_string_literal: true

require 'google/apis/drive_v3'

module Api
  module V1
    class ToolsController < ApiNoauthController
      before_action :find_dify_api_key, only: [:export_to_notion]

      def find_dify_api_key
        api_key = request.headers['X-API-KEY']
        @dify_api_key = DifyApiKey.find_by(api_key:)
      end

      def upload_directly_ocr
        file = params[:file]

        # 呢道先判斷一下文件的類型先，如果係可以做 ocr 的野，先會去做 ocr
        begin
          file_extension = File.extname(file.original_filename).downcase if file.present?
          allowed_extensions = ['.doc', '.docx', '.pdf', '.jpg', '.jpeg', '.png', '.gif']
          @file_url = AzureService.upload(file) if file.present?

          if allowed_extensions.include?(file_extension)
            ocr_res = RestClient.post("#{ENV['DOCAI_ALPHA_URL']}/alpha/ocr", document_url: @file_url)
            content = JSON.parse(ocr_res)['result']
            render json: { success: true, file_url: @file_url, content: }, status: :ok
          else
            render json: { success: true, file_url: @file_url, content: @file_url }, status: :ok
          end
        rescue StandardError => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end

        # begin
        #   @file_url = AzureService.upload(file) if file.present?
        #   ocr_res = RestClient.post("#{ENV['DOCAI_ALPHA_URL']}/alpha/ocr", document_url: @file_url)
        #   content = JSON.parse(ocr_res)['result']
        #   render json: { success: true, file_url: @file_url, content: }, status: :ok
        # rescue StandardError => e
        #   render json: { success: false, error: e.message }, status: :unprocessable_entity
        # end
      end

      def text_to_pdf
        content = params[:content]
        begin
          pdfBlob = FormProjectionService.text2Pdf(content)
          blob2Base64 = FormProjectionService.exportImage2Base64(pdfBlob)
          render json: { success: true, pdf: blob2Base64 }, status: :ok
        rescue StandardError => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end
      end

      def text_to_png
        content = params[:content]
        begin
          pngBlob = ImageService.html2Png(content)
          blob2Base64 = FormProjectionService.exportImage2Base64(pngBlob)
          render json: { success: true, png: blob2Base64 }, status: :ok
        rescue StandardError => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end
      end

      def upload_html_to_pdf
        content = params[:content]
        begin
          pdfBlob = FormProjectionService.text2Pdf(content)
          file_url = AzureService.uploadBlob(pdfBlob, 'chatting_report.pdf', 'application/pdf')
          render json: { success: true, file_url: }, status: :ok
        rescue StandardError => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end
      end

      def dify_prompt_wrapper
        user = GeneralUser.where(phone: params[:whatsapp]).first

        return json_fail('no this user') if user.nil?

        query = params[:query]

        pw = DifyService.prompt_wrapper(user, query)

        render json: { success: true, prompt: pw }
      end

      def export_to_notion
        title = params[:title]
        content = params[:content]
        notion_token = NotionService.fetch_token_from_db(@dify_api_key.domain, @dify_api_key.workspace)
        notion_service = NotionService.new(token: notion_token)
        response = notion_service.create_page(title, content)

        if response['object'] == 'page'
          render json: { status: 'success', page_id: response['id'] }, status: :created
        else
          render json: { status: 'error', message: response['message'] }, status: :unprocessable_entity
        end
      end

      def dify_chatbot_report
        gateway = nil
        local_port = nil

        begin
          gateway, local_port = SshTunnelService.open(
            params[:domain],
            'akali',
            'akl123123'
          )

          if gateway.nil? || local_port.nil?
            render json: { error: 'SSH tunnel setup failed' }, status: 500
            return
          end

          # 使用 PG 库直接连接到 PostgreSQL 数据库
          conn = PG.connect(
            dbname: 'dify',
            user: 'postgres',
            password: 'difyai123456',
            host: 'localhost',
            port: local_port
          )

          # 执行 SQL 查询
          sql = "SELECT * FROM messages WHERE conversation_id = $1 AND created_at >= NOW() - INTERVAL '15 minutes' ORDER BY created_at ASC"
          result = conn.exec_params(sql, [params[:conversation_id]])

          # 转换结果为 JSON
          @items = []
          @items = result.map do |record|
            { "subtitle": record['query'], paragraph: record['answer'] }
          end

          @title = params[:title] || 'Conversation Report'

          # Render HTML as a string
          # binding.pry
          # puts "Current view paths: #{lookup_context.view_paths.paths.map(&:to_s)}"
          html_string = render_to_string(template: 'api/v1/tools/report', formats: [:html], layout: false)

          # binding.pry
          pdfBlob = FormProjectionService.text2Pdf(html_string)
          file_url = AzureService.uploadBlob(pdfBlob, "#{@title}.pdf", 'application/pdf')
          render json: { success: true, file_url: }, status: :ok

          # render "report.html.erb"
          # 渲染结果
          # render json: messages
        ensure
          # 关闭数据库连接
          conn&.close

          # 关闭 SSH 隧道
          SshTunnelService.close(gateway) if gateway
        end
      end

      def upload_html_to_png
        content = params[:content]
        begin
          uri = URI("#{ENV['EXAMHERO_URL']}/tools/html_to_png")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json', 'Accept' => 'application/json')
          request.body = {
            html_content: content
          }.to_json
          http.read_timeout = 600_000

          response = http.request(request)
          res = JSON.parse(response.body)

          if res['screenshot'].present?
            img = Base64.strict_decode64(res['screenshot'])
            screenshot = Magick::ImageList.new.from_blob(img)
            file_url = AzureService.uploadBlob(screenshot.to_blob, 'chatting_report.png', 'image/png')
            render json: { success: true, file_url: }, status: :ok
          else
            render json: { success: false, error: 'Something went wrong' }, status: :unprocessable_entity
          end
        rescue StandardError => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end
      end

      def auth_dify_user_google_drive?
        dify_user_id = params[:dify_user_id]
        workspace = params[:workspace]
        domain = params[:domain]

        google_drive_access_token = DifyGoogleDriveService.fetch_token_from_db(domain, workspace, dify_user_id)

        if google_drive_access_token.present?
          render json: { success: true, status: 'success' }, status: :ok
        else
          render json: { success: false, error: 'Not authenticated' }, status: :ok
        end
      rescue StandardError => e
        render json: { success: false, error: 'An error occurred', details: e.message }, status: :internal_server_error
      end

      def auth_dify_user_google_drive
        dify_user_id = params[:dify_user_id]
        workspace = params[:workspace]
        domain = params[:domain]
        access_token = params[:access_token]

        DifyGoogleDriveService.insert_token_to_db(domain, workspace, access_token, dify_user_id)

        render json: { success: true, status: 'success' }, status: :ok
      rescue StandardError => e
        render json: { success: false, error: 'An error occurred', details: e.message }, status: :internal_server_error
      end

      def revoke_dify_user_google_drive
        dify_user_id = params[:dify_user_id]
        workspace = params[:workspace]
        domain = params[:domain]

        DifyGoogleDriveService.delete_token_from_db(domain, workspace, dify_user_id)

        render json: { success: true, status: 'success' }, status: :ok
      rescue StandardError => e
        render json: { success: false, error: 'An error occurred', details: e.message }, status: :internal_server_error
      end

      def export_docx_to_google_drive
        dify_user_id = params[:dify_user_id]
        workspace = params[:workspace]
        domain = params[:domain]
        content = params[:content]
        file_name = params[:file_name] || 'dify_user_file.docx'

        file_metadata = {
          name: file_name,
          mime_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        }

        file = Utils.text_to_docx(content, file_metadata['name'])

        google_drive_access_token = DifyGoogleDriveService.fetch_token_from_db(domain, workspace, dify_user_id)

        dify_user_credentials = Google::Auth::UserRefreshCredentials.new(
          client_id: ENV['GOOGLE_GMAIL_READ_INCOMING_CLIENT_ID'],
          client_secret: ENV['GOOGLE_GMAIL_READ_INCOMING_CLIENT_SECRET'],
          refresh_token: google_drive_access_token,
          scope: 'https://www.googleapis.com/auth/drive.file'
        )

        dify_user_credentials.fetch_access_token!

        drive_service = Google::Apis::DriveV3::DriveService.new
        drive_service.authorization = dify_user_credentials
        drive_service.create_file(file_metadata, upload_source: file,
                                                 content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')

        render json: { success: true, status: 'success' }
      rescue Google::Apis::AuthorizationError => e
        render json: { success: false, error: 'Authorization error', details: e.message }, status: :unauthorized
      rescue StandardError => e
        render json: { success: false, error: 'An error occurred', details: e.message }, status: :internal_server_error
      end

      def list_google_drive_files
        dify_user_id = params[:dify_user_id]
        workspace = params[:workspace]
        domain = params[:domain]

        google_drive_access_token = DifyGoogleDriveService.fetch_token_from_db(domain, workspace, dify_user_id)

        dify_user_credentials = Google::Auth::UserRefreshCredentials.new(
          client_id: ENV['GOOGLE_GMAIL_READ_INCOMING_CLIENT_ID'],
          client_secret: ENV['GOOGLE_GMAIL_READ_INCOMING_CLIENT_SECRET'],
          refresh_token: google_drive_access_token,
          scope: 'https://www.googleapis.com/auth/drive.file'
        )

        drive_service = Google::Apis::DriveV3::DriveService.new

        drive_service.authorization = dify_user_credentials

        response = drive_service.list_files(page_size: 10, fields: 'nextPageToken, files(id, name)')
        render json: { success: true, files: response.files }, status: :ok
      rescue Google::Apis::AuthorizationError => e
        render json: { success: false, error: 'Authorization error', details: e.message }, status: :unauthorized
      rescue StandardError => e
        render json: { success: false, error: 'An error occurred', details: e.message }, status: :internal_server_error
      end
    end
  end
end
