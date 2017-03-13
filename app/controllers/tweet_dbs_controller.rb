class TweetDbsController < ApplicationController
  before_action :set_tweet_db, only: [:show, :edit, :update, :destroy]

  # GET /tweet_dbs
  # GET /tweet_dbs.json

  def index
    @tweet_dbs = TweetDb.all.sort({"retweet":-1})
  end

  # GET /tweet_dbs/1
  # GET /tweet_dbs/1.json
  def show
  end

  # GET /tweet_dbs/new
  def new
    @tweet_db = TweetDb.new
  end

  # GET /tweet_dbs/1/edit
  def edit
  end

  # POST /tweet_dbs
  # POST /tweet_dbs.json
  def create
    @tweet_db = TweetDb.new(tweet_db_params)

    respond_to do |format|
      if @tweet_db.save
        format.html { redirect_to @tweet_db, notice: 'Tweet db was successfully created.' }
        format.json { render :show, status: :created, location: @tweet_db }
      else
        format.html { render :new }
        format.json { render json: @tweet_db.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tweet_dbs/1
  # PATCH/PUT /tweet_dbs/1.json
  def update
    respond_to do |format|
      if @tweet_db.update(tweet_db_params)
        format.html { redirect_to @tweet_db, notice: 'Tweet db was successfully updated.' }
        format.json { render :show, status: :ok, location: @tweet_db }
      else
        format.html { render :edit }
        format.json { render json: @tweet_db.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tweet_dbs/1
  # DELETE /tweet_dbs/1.json
  def destroy
    @tweet_db.destroy
    respond_to do |format|
      format.html { redirect_to tweet_dbs_url, notice: 'Tweet db was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tweet_db
      @tweet_db = TweetDb.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tweet_db_params
      params.require(:tweet_db).permit(:tweet, :idioma, :data, :pais, :localizacao, :favoritos, :retweet, :criador, :id_tweet, :tag_associada, :hora_extracao,:hora_criacao,:dispositivo)
    end
end
