class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :set_ransack, only: [:index, :show]
  skip_before_action :require_login, only: [:index, :show]

  # GET /articles
  # GET /articles.json
  def index
    @articles = @q.result(distinct: true).page(params[:page]).per(Gorilla.per_page)
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    redirect_to root_path if @article.undisclosed? && !current_user
    @user = @article.user
    @comments = @article.comments
  end

  # GET /articles/new
  def new
    @article = Article.new
  end

  # GET /articles/1/edit
  def edit
  end

  # POST /articles
  # POST /articles.json
  def create
    @article = Article.new(article_params)
    @article.user_id = current_user.id

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: 'Article was successfully created.' }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, notice: 'Article was successfully updated.' }
        format.json { render :show, status: :ok, location: @article }
      else
        format.html { render :edit }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article.destroy
    respond_to do |format|
      format.html { redirect_to articles_url, notice: 'Article was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def picture
    full_path = "#{Rails.root}/public/picture/#{params[:id]}/#{params[:filename]}"

    #return error404 if full_path.include?('..') || !File.file?(full_path)
    send_file(full_path, type: mime_type(params[:filename].split('.').last), disposition: :inline, stream: true)
  end

  def remove_picture
    picture = Picture.find(params[:id])
    picture.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params[:id])
    end

    def set_ransack
      if Gorilla.hide_future_article && !current_user
        article = Article.where('posted_at <= ?', DateTime.now)
      else
        article = Article.all
      end
      @q = article.ransack(search_params)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      params.require(:article).permit(:title, :body, :body, :posted_at, :tag_list,
        pictures_attributes: [:id, :image, :article_id, :_destroy])
    end

    def search_params
      param = params.require(:q).permit(:title_or_tags_name_cont_any, :tags_name_eq)
      param[:title_or_tags_name_cont_any] = param[:title_or_tags_name_cont_any].split(/ |　/) unless param[:tags_name_eq]
      return param
    rescue
      nil
    end
end
