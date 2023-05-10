class Api::V1::DocumentsController < ApiController
  before_action :set_document, only: [:show, :update, :destroy, :approval]
  before_action :current_user_documents, only: [:show_latest_predict, :show_specify_date_latest_predict]
  before_action :authenticate_user!, only: [:approval]
  # before_action :require_admin, only: []

  def index
    @documents = Document.all
  end

  # Show document by id
  def show
    @document = Document.find(params[:id])
    render json: { success: true, document: @document }, status: :ok
  end

  # Show documents by ids
  def show_by_ids
    puts params[:ids]
    @documents = Document.find(params[:ids]).as_json(except: [:label_list])
    render json: { success: true, documents: @documents }, status: :ok
  end

  # Show documents by name like name param
  def show_by_name
    @document = Document.where("name like ?", "%#{params[:name]}%").order(:created_at => :desc).as_json(except: [:label_list])
    render json: { success: true, documents: @document }, status: :ok
  end

  # Show documents by content like content param
  def show_by_content
    @document = Document.includes([:taggings]).where("content like ?", "%#{params[:content]}%").order(:created_at => :desc).page params[:page]
    render json: { success: true, documents: @document, meta: pagination_meta(@document) }, status: :ok
  end

  # Show documents by ActsAsTaggableOn tag id
  def show_by_tag
    tag = ActsAsTaggableOn::Tag.find(params[:tag_id])
    @document = Document.tagged_with(tag).order(:created_at => :desc).as_json(except: [:label_list])
    render json: { success: true, documents: @document }, status: :ok
  end

  # Show documents by date
  def show_by_date
    @document = Document.includes([:taggings]).where("created_at >= ?", params[:date]).order(:created_at => :desc).page params[:page]
    render json: { success: true, documents: @document, meta: pagination_meta(@document) }, status: :ok
  end

  # Show documents by filter
  def show_by_tag_and_content
    tag = ActsAsTaggableOn::Tag.find(params[:tag_id])
    content = params[:content] || ""
    # if params[:from] == "" or params[:from] == nil, then from = "1970-01-01"
    # from = params[:from] || "1970-01-01"
    # to = params[:to] || Date.today
    from = params[:from].present? ? params[:from] : "1970-01-01"
    to = params[:to].present? ? params[:to] : Date.today
    puts tag.inspect
    @document = Document.includes([:taggings]).tagged_with(tag).where("content like ?", "%#{content}%").where("documents.created_at >= ?", from.to_date).where("documents.created_at <= ?", to.to_date).order(:created_at => :desc).page params[:page]
    render json: { success: true, documents: @document, meta: pagination_meta(@document) }, status: :ok
  end

  # Show and Predict the Latest Uploaded Document
  def show_latest_predict
    @document = @current_user_documents.where(status: :ready).order(:created_at).page(params[:page]).per(1)
    if @document.present?
      res = RestClient.get ENV["DOCAI_ALPHA_URL"] + "/classification/predict?id=" + @document.last.id.to_s
      @tag = Tag.find(JSON.parse(res)["label"]["id"]).as_json(include: :functions)
      render json: { success: true, prediction: { tag: @tag, document: @document.last }, meta: pagination_meta(@document) }, status: :ok
    else
      render json: { success: false, error: "No document found" }, status: :ok
    end
  end

  # Show and Predict the Specify Date Latest Uploaded Document
  def show_specify_date_latest_predict
    @document = @current_user_documents.where(status: :ready).where("created_at >= ?", params[:date].to_date).where("created_at <= ?", params[:date].to_date + 1.day).order(:created_at).page(params[:page]).per(1)
    @unconfirmed_count = @current_user_documents.where.not(status: :confirmed).where("created_at >= ?", params[:date].to_date).where("created_at <= ?", params[:date].to_date + 1.day).order(:created_at).count
    @confirmed_count = @current_user_documents.where(status: :confirmed).where("created_at >= ?", params[:date].to_date).where("created_at <= ?", params[:date].to_date + 1.day).order(:created_at).count
    if @document.present?
      res = RestClient.get ENV["DOCAI_ALPHA_URL"] + "/classification/predict?id=" + @document.last.id.to_s
      @tag = Tag.find(JSON.parse(res)["label"]["id"]).as_json(include: :functions)
      render json: { success: true, prediction: { tag: @tag, document: @document.last }, confirmed_count: @confirmed_count, unconfirmed_count: @unconfirmed_count, meta: pagination_meta(@document) }, status: :ok
    else
      render json: { success: false, error: "No document found" }, status: :ok
    end
  end

  def create
    @document = Document.new(document_params)
    file = params["document"]["file"]
    @document.storage_url = AzureService.upload(file) if file.present?
    if @document.save
      render :show
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def destroy
    @document = Document.find(params[:id])
    if @document.destroy
      render json: { success: true }, status: :ok
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def update
    @document = Document.find(params[:id])
    if @document.update(document_params)
      render json: { success: true, document: @document }, status: :ok
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def approval
    # binding.pry
    @document.approval_user = current_user
    @document.approval_at = DateTime.current
    @document.approval_status = params["status"]
    if @document.save
      render :show
    else
      json_fail("Document approval failed")
    end
  end

  def tags
    @tags = Documents.all_tags
    render json: @tags
  end

  def ocr
    @document = Document.first
    OcrJob.perform_async(@document.id)
    json_success("OCR job is queued")
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name, :storage_url, :content, :status, :folder_id)
  end

  def document_search_params
    params.permit(:content, :tag_id, :from, :to)
  end

  def current_user_documents
    @current_user_documents = Document.where(user_id: current_user.id).or(Document.where(user_id: nil))
  end

  def pagination_meta(object)
    {
      current_page: object.current_page,
      next_page: object.next_page,
      prev_page: object.prev_page,
      total_pages: object.total_pages,
      total_count: object.total_count,
    }
  end
end
