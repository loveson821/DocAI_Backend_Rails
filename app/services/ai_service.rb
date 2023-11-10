# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class AiService
  def self.generateContentByDocuments(query, content, response_format, language, topic, style)
    puts query, content, response_format, language, topic, style
    res = RestClient.post "#{ENV['PORMHUB_URL']}/prompts/docai_documents_generate_content/run.json", { params: {
      query:,
      response_format:,
      language:,
      topic:,
      style:,
      content:
    } }
    res = JSON.parse(res)
    puts "Response from OpenAI: #{res}"
    # puts response["error"].present?
    # if response["error"].present? && response["error"]["code"] == "context_length_exceeded"
    #   return "文件太多了，系統無法處理，請減少文件數量！"
    # end

    # if res.success?
    #   return res.data.content
    # end

    # puts "Response: #{response["choices"][0]["message"]["content"]}"
    # Utils.cleansingContentFromGPT(response['choices'][0]['message']['content'])
    puts res['data']['content']
    res['data']['content']
  end

  def self.documentSmartExtraction(schema, content, storage_url, data_schema)
    puts "DocumentSmartExtraction: #{schema}, #{content}, #{storage_url} #{data_schema}"
    if schema.first['query'].is_a?(Array)
      puts 'DocumentSmartExtraction: Array Task!'
      # res = RestClient.post("#{ENV['DOCAI_ALPHA_URL']}/smart_extraction_schema/map_reduce", { storage_url:, schema:, data_schema: }.to_json, { content_type: :json, accept: :json, timeout: 30000 })
      # puts "Res: #{res}"
      uri = URI("#{ENV['DOCAI_ALPHA_URL']}/smart_extraction_schema/map_reduce")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https' # 啟用 SSL/TLS 如果是 https URL
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json', 'Accept' => 'application/json')
      request.body = { storage_url:, schema:, data_schema: }.to_json

      # 設定超時
      http.read_timeout = 30_000 # 秒為單位

      # 發送請求
      response = http.request(request)

      # 解析響應
      res = JSON.parse(response.body)
      puts "Res: #{res}"
    else
      res = RestClient.post "#{ENV['PORMHUB_URL']}/prompts/docai_document_smart_extraction/run.json", { params: {
        schema:,
        content:,
        data_schema:
      } }
      res = JSON.parse(res)
      puts "Response from OpenAI: #{res}"
    end
    res['data']
  end

  def self.assistantQA(query, chat_history, schema, metadata)
    res = RestClient.post("#{ENV['DOCAI_ALPHA_URL']}/documents/embedding/qa", {
      query:,
      chat_history:,
      schema:,
      metadata:
    }.to_json, { content_type: :json, accept: :json })
    res = JSON.parse(res)
    puts "Response from Document Embedding QA: #{res}"
    if res['status'] == true
      res
    else
      res['message']
    end
  end

  def self.assistantQASuggestion(schema, metadata)
    res = RestClient.post("#{ENV['DOCAI_ALPHA_URL']}/documents/embedding/qa/suggestion", {
      schema:,
      metadata:
    }.to_json, { content_type: :json, accept: :json })
    res = JSON.parse(res)
    puts "Response from Document Embedding QA Suggestion: #{res}"

    if res['status'] == true
      res['suggestion']
    else
      res['message']
    end
  end
end
