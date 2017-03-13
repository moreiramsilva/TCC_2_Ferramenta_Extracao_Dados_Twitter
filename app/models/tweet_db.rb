class TweetDb
  include Mongoid::Document
  field :tweet, type: String
  field :idioma, type: String
  field :data, type: String
  field :pais, type: String
  field :localizacao, type: String
  field :favoritos, type: Integer
  field :retweet, type: Integer
  field :criador, type: String
  field :id_tweet, type: String
  field :tag_associada, type: String
  field :hora_extracao, type: Date
  field :hora_criacao, type: String
  field :dispositivo, type: String
end
