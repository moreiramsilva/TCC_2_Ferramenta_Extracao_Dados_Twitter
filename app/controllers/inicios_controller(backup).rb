require "twitter"
require "data_mining"
require "apriori"
require "sentimentalizer"

class IniciosController < ApplicationController

before_action :set_tweet_db, only: [:show, :edit, :update, :destroy]

def index
end

def excluir
  	@deletar = params[:arg]
	TweetDb.where(tag_associada: @deletar).destroy
	redirect_to :action=>'index'
end

def show
end

def exibir
	@item = params[:arg]
	@tweet_dbs = TweetDb.where(tag_associada: @item)
end

def busca
  		@parametro = params[:q]
  		@limite_max = params[:p]
  		@result = params[:resultado]
  		@tipo_de_analise = params[:tipo]

   		client = Twitter::REST::Client.new do |config|
			config.consumer_key    = "PrtRg9rMITnfjKHBZjm7uYrVG"
  			config.consumer_secret = "i4GNeXICwjaVbYSHcdeQsiIEBVzHKmotgy0q7JZRB4ZYzxsVAF"
  			config.access_token        = "164776991-Z14aPkk1LIL4p0NEIRUvlGBmU7EnteePZ5PI86fE"
  			config.access_token_secret = "MnitBUBh8PRCem7DbIdUBSnPB6MlhLxE5Co7tk3nqGyYO"
		  end

		  	tweet_contador = 0
			loc_contador = 0
			
			time = Time.new
			analyzer = Analyzer.new

			@hora_atual = time.strftime("%Y-%m-%d")

			localizacao = {"Pais" => "Tweets"}
			cidade = {"Cidades" => "Tweets"}
			idioma =  {"Idioma" => "Tweets"}
			date =  {"Data" => "Tweets"}
			horario = {"Horario" => "Tweets"}
			disposit = {"Tipo de Dispositivo Utilizado" => "Tweets", "Twitter Web Client"=>0, "Twitter for iPhone"=>0, "Twitter for Windows"=>0, "Twitter for iPad"=>0, "Twitter for Android"=>0, "Twitter for Windows Phone"=>0, "Twitter for Mac"=>0, "Twitter for BlackBerry"=>0, "Plugins em sites terceiros"=>0}
			sentimento = {"Sentimento" => "Quantidade" , "Negativo" =>0, "Neutro" =>0, "Positivo" =>0}

		  client.search(@parametro , result_type: @result).take(@limite_max.to_i).each do |a|

		  	tweet_contador = tweet_contador + 1

		  	tempo = a.created_at.to_s.split(" ")
			data = tempo[0]

			if date.has_key?(data) 
    			date[data] = date[data] + 1
  			else
  				date[data] = 1
  			end

  			hora_completa = tempo[1]
  			hora = hora_completa[0..4]
  			
  			if horario.has_key?(hora) 
    			horario[hora] = horario[hora] + 1
  			else
  				horario[hora] = 1
  			end

			postado =  a.source.to_s.split(">").last
			gadget = postado.split("<").first

			if disposit.has_key?(gadget) 
    			disposit[gadget] = disposit[gadget] + 1
  			else
  				disposit["Plugins em sites terceiros"] = disposit["Plugins em sites terceiros"] + 1
  			end


			if(a.place.country_code.to_s.size > 0)

				loc_contador = loc_contador + 1
			 	lugar = a.place.country_code

			 	if localizacao.has_key?(lugar) 
     				localizacao[lugar] = localizacao[lugar] + 1
  	 			else
  	 				localizacao[lugar] = 1
  	 			end
  	 		end

  	 		if(a.place.full_name.to_s.size > 0)
  	 			city = a.place.full_name.to_s

  	 			if cidade.has_key?(city)
  	 				cidade[city] = cidade[city] + 1
  	 			else
  	 				cidade[city] = 1
  	 			end
  	 		end

  			lingua = a.lang

			if idioma.has_key?(lingua) 
    			idioma[lingua] = idioma[lingua] + 1
  			else
  				idioma[lingua] = 1
  			end
  			
  			if (a.lang == "en")
  	
  				teste = analyzer.process(a.full_text.to_s)
				
				if(teste.sentiment == ":(")
					sentimento["Negativo"] = sentimento["Negativo"] + 1	
				elsif (teste.sentiment == ":|")
					sentimento["Neutro"] = sentimento["Neutro"] + 1
				elsif (teste.sentiment == ":)")
					sentimento["Positivo"] = sentimento["Positivo"] + 1	
				end
			end

  			criador = a.uri.to_s

		  	r = TweetDb.new
		  		r.tweet = a.full_text.to_s
		  		r.idioma = a.lang.to_s
				r.data = data
			  	r.pais = a.place.country_code.to_s
			  	r.localizacao = a.place.full_name.to_s
			  	r.favoritos = a.favorite_count.to_i
			  	r.retweet = a.retweet_count.to_i
			  	r.tag_associada = @parametro
			  	r.id_tweet = a.id.to_s
			  	r.criador = criador.split("status/").first
			  	r.hora_extracao = @hora_atual
			  	r.hora_criacao = hora

			  	if(gadget = "Twitter Web Client" || "Twitter for iPhone" || "Twitter for Windows" || "Twitter for iPad" || "Twitter for Android" || "Twitter for Windows Phone" || "Twitter for Mac" || "Twitter for BlackBerry")
    				r.dispositivo = gadget
  				else
  					r.dispositivo = "Plugins em sites terceiros"
  				end
			r.save

		  end

		  t = Mineracao.new(@parametro, @hora_atual, @tipo_de_analise)
		  t.nuvem_de_palavras
		  t.mineracao_apriori

		  @favoritos = TweetDb.where(tag_associada: @parametro).where(hora_extracao: @hora_atual).sort({"favoritos":-1}).limit(1)
		  @retweetados = TweetDb.where(tag_associada: @parametro).where(hora_extracao: @hora_atual).sort({"retweet":-1}).limit(1)
		  
		  @loc = localizacao.to_a
		  @cidd = cidade.to_a
		  @ling = idioma.to_a
		  @dis = disposit.to_a
		  @dat = date.to_a
		  @hor = horario.to_a
		  @contador = tweet_contador
		  @contador_loc = loc_contador
		  @sent = sentimento.to_a
end
end

class Analyzer
  
  def initialize
    Sentimentalizer.setup
  end

  def process(phrase)
    Sentimentalizer.analyze phrase
  end
end


class Mineracao

include Mongoid::Document

	def initialize(argum , argum2, argum3)
			@argum = argum
			@argum2 = argum2
			@argum3 = argum3
	end

	def nuvem_de_palavras
			
			palavras_comum = File.open('Stop_words.txt','r').read.encode!('UTF-8','UTF-8', :invalid => :replace).split("\n")

			num_palavras = Hash.new(0)

			emoticon = {"😄" => 0 ,"😃" => 0 ,"😀" => 0 ,"😊" => 0 ,"☺️" => 0 ,"😉" => 0 ,"😍" => 0 ,"😘" => 0 ,"😚" => 0 ,"😗" => 0 ,"😙" => 0 ,"😜" => 0 ,"😝" => 0 ,"😛" => 0 ,"😳" => 0 ,"😁" => 0 ,"😔" => 0 ,"😌" => 0 ,"😒" => 0 ,"😞" => 0 ,"😣" => 0 ,"😢" => 0 ,"😂" => 0 ,"😭" => 0 ,"😪" => 0 ,"😥" => 0 ,"😰" => 0 ,"😅" => 0 ,"😓" => 0 ,"😩" => 0 ,"😫" => 0 ,"😨" => 0 ,"😱" => 0 ,"😠" => 0 ,"😡" => 0 ,"😤" => 0 ,"😖" => 0 ,"😆" => 0 ,"😋" => 0 ,"😷" => 0 ,"😎" => 0 ,"😴" => 0 ,"😵" => 0 ,"😲" => 0 ,"😟" => 0 ,"😦" => 0 ,"😧" => 0 ,"😈" => 0 ,"👿" => 0 ,"😮" => 0 ,"😬" => 0 ,"😐" => 0 ,"😕" => 0 ,"😯" => 0 ,"😶" => 0 ,"😇" => 0 ,"😏" => 0 ,"😑" => 0 ,"😺" => 0 ,"😸" => 0 ,"😻" => 0 ,"😽" => 0 ,"😼" => 0 ,"🙀" => 0 ,"😿" => 0 ,"😹" => 0 ,"😾" => 0 ,"🙈" => 0 ,"🙉" => 0 ,"🙊" => 0 ,"💩" => 0 ,"💤" => 0 ,"👅" => 0 ,"👄" => 0 ,"👍" => 0 ,"👎" => 0 ,"👌" => 0 ,"👊" => 0 ,"✊" => 0 ,"✌️" => 0 ,"👋" => 0 ,"✋" => 0 ,"👐" => 0 ,"👆" => 0 ,"👇" => 0 ,"👉" => 0 ,"👈" => 0 ,"🙌" => 0 ,"🙏" => 0 ,"☝️" => 0 ,"👏" => 0 ,"💪" => 0 ,"💛" => 0 ,"💙" => 0 ,"💜" => 0 ,"💚" => 0 ,"❤️" => 0 ,"💔" => 0 ,"💗" => 0 ,"💓" => 0 ,"💕" => 0 ,"💖" => 0 ,"💞" => 0 ,"💘" => 0 ,"💋" => 0 ,"💭" => 0}
						
			if (@argum3 == "atual")
				busca = TweetDb.where(tag_associada: @argum).where(hora_extracao: @argum2)
			else
				busca = TweetDb.where(tag_associada: @argum)
			end

			busca.each do |cloud|	  
			tag = cloud.tweet.split
			
			#coloca tudo em minusculo
				tag.map!{|c| c.downcase.strip}

				tag.map!{|c| c.gsub(/(ç)/ ,'c')}
				tag.map!{|c| c.gsub(/(àáãâ)/ , 'a')}
				tag.map!{|c| c.gsub(/(èéẽê)/ ,'e')}
				tag.map!{|c| c.gsub(/(óòõô)/ ,'o')}
				tag.map!{|c| c.gsub(/(íìĩî)/ ,'i')}
				tag.map!{|c| c.gsub(/(üúùũû)/ ,'u')}
				tag.map!{|c| c.gsub(/(ñ)/ , 'n')}
				
				tag.each do |palavra|

					if emoticon.has_key?(palavra) 
    					emoticon[palavra] +=  1
					end
				end

			#remove caracteres especiais
				tag.map!{|c| c.gsub(/[^a-z0-9\-]/,'')}

			# hash de palavras e repeticoes
		
				tag.each do |palavra|

					if(palavra[0..4] == "https")
					
					elsif(palavra == @argum.downcase)
					
					elsif (palavra.size < 4)
					
					else
						
						num_palavras[palavra] += 1
					end
				end

			# remove palavras comuns da lista
				palavras_comum.each do |palavra|
			    	num_palavras.delete(palavra)
			    	num_palavras.delete('')
				end

			end

			num_palavras = num_palavras.sort_by {|palavra,count| count}.reverse

			@texto = "["
			virgulas = 0
			max_cloud = 100

			num_palavras.take(max_cloud).each do |palavra, count|

			@texto = @texto + "{"+"\"text\"" + ":" + "\"#{palavra}\"" + "," + "\"size\"" + ":" + "#{count}" +"}"
			virgulas = virgulas + 1 
			@texto = @texto + "," if virgulas < max_cloud
			end
		@texto += "]"

		emoticon = emoticon.sort_by {|palavra , count| count}.reverse

		$emoji = emoticon.delete_if {|palavra , count| count <= 0 }

		$txt = @texto
	end

	def mineracao_apriori

		dados = []
		dados2 = []
		dados3 = []

		if (@argum3 == "atual")
			busca = TweetDb.where(tag_associada: @argum).where(hora_extracao: @argum2)
		else
			busca = TweetDb.where(tag_associada: @argum)
		end

		busca.each do |miner|
			  
		#primeiros conjunto de parametros do apriori

		tg1 = miner.idioma #pegando primeiro parametro para a mineração 
		tg2 = miner.data #pegando segundo parametro para a mineração

		item =  Array.new
		item.push(tg1)
		item.push(tg2)

  		dados.push(item)

  		#segundo conjunto de parametro do apriori


		tg3 = miner.hora_criacao #pegando primeiro parametro para a mineração 
		tg4 = miner.data #pegando segundo parametro para a mineração

		item2 =  Array.new
		item2.push(tg3)
		item2.push(tg4)

  		dados2.push(item2)


  		#terceiro conjunto de paramentros do apriori


		tg5 = miner.criador #pegando primeiro parametro para a mineração
		tg6 = miner.data #pegando segundo parametro para a mineração

		item3 =  Array.new
		item3.push(tg5)
		item3.push(tg6)

  		dados3.push(item3)

		end
		
		#analise do data e hora

		support = 5
	 	confidence = 70
		item_set = Apriori::ItemSet.new(dados)
	 	variavel = item_set.mine(support, confidence)
	 	$mining = variavel.to_a

	 	#analise do pais e dispositivo

	 	support = 1
	 	confidence = 10
	 	item_set2 = Apriori::ItemSet.new(dados2)
	 	variavel2 = item_set2.mine(support, confidence)
	 	$mining2 = variavel2.to_a
	end
end
