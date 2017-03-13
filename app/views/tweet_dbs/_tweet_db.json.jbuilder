json.extract! tweet_db, :id, :tweet, :idioma, :data, :pais, :localizacao, :favoritos, :retweet, :tag_associada, :created_at, :updated_at
json.url tweet_db_url(tweet_db, format: :json)