require 'test_helper'

class TweetDbsControllerTest < ActionController::TestCase
  setup do
    @tweet_db = tweet_dbs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tweet_dbs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tweet_db" do
    assert_difference('TweetDb.count') do
      post :create, tweet_db: { criador: @tweet_db.criador, data: @tweet_db.data, dispositivo: @tweet_db.dispositivo, favoritos: @tweet_db.favoritos, hora_criacao: @tweet_db.hora_criacao, hora_extracao: @tweet_db.hora_extracao, id_tweet: @tweet_db.id_tweet, idioma: @tweet_db.idioma, localizacao: @tweet_db.localizacao, pais: @tweet_db.pais, retweet: @tweet_db.retweet, tag_associada: @tweet_db.tag_associada, tweet: @tweet_db.tweet }
    end

    assert_redirected_to tweet_db_path(assigns(:tweet_db))
  end

  test "should show tweet_db" do
    get :show, id: @tweet_db
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @tweet_db
    assert_response :success
  end

  test "should update tweet_db" do
    patch :update, id: @tweet_db, tweet_db: { criador: @tweet_db.criador, data: @tweet_db.data, dispositivo: @tweet_db.dispositivo, favoritos: @tweet_db.favoritos, hora_criacao: @tweet_db.hora_criacao, hora_extracao: @tweet_db.hora_extracao, id_tweet: @tweet_db.id_tweet, idioma: @tweet_db.idioma, localizacao: @tweet_db.localizacao, pais: @tweet_db.pais, retweet: @tweet_db.retweet, tag_associada: @tweet_db.tag_associada, tweet: @tweet_db.tweet }
    assert_redirected_to tweet_db_path(assigns(:tweet_db))
  end

  test "should destroy tweet_db" do
    assert_difference('TweetDb.count', -1) do
      delete :destroy, id: @tweet_db
    end

    assert_redirected_to tweet_dbs_path
  end
end
