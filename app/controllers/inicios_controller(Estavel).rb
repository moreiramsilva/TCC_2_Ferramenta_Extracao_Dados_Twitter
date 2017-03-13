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
		  	
		time = Time.new
		@hora_atual = time.strftime("%Y-%m-%d")

		client.search(@parametro , result_type: @result).take(@limite_max.to_i).each do |a|

		  	#CRIADOS
		  	criador = a.uri.to_s
		  	
		  	#DATA E HORA
		  	tempo = a.created_at.to_s.split(" ") #TEMPO TOTAL
			data = tempo[0] #DATA
			hora_completa = tempo[1] #HORA COMPLETA COM FUSO HORARIO
	  		hora = hora_completa[0..4] #HORA SEM FUSO HORARIO E SEGUNDOS
	  		
	  		#DIPOSITIVO
	  		postado =  a.source.to_s.split(">").last
			gadget = postado.split("<").first
			
			check_dispositivo = {"Twitter Web Client"=>"Twitter Web Client", "Twitter for iPhone"=>"Twitter for iPhone", "Twitter for Windows"=>"Twitter for Windows", "Twitter for iPad"=>"Twitter for iPad","Twitter for Android"=>"Twitter for Android", "Twitter for Windows Phone"=>"Twitter for Windows Phone", "Twitter for Mac"=>"Twitter for Mac", "Twitter for BlackBerry"=>"Twitter for BlackBerry"}
			
			tipo_dispositivo = "Plugins em sites terceiros"

			if check_dispositivo.has_key?(gadget) 
    			tipo_dispositivo = check_dispositivo[gadget]
  			end

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
				r.dispositivo = tipo_dispositivo
			r.save
		end

		self.analise_de_padrao_e_sentimentos
		self.nuvem_de_palavras
		self.mineracao_apriori

		#FAVORITOS 
		@favoritos = TweetDb.where(tag_associada: @parametro).where(hora_extracao: @hora_atual).sort({"favoritos":-1}).limit(1)
		#MAIS RETWEETADOS
		@retweetados = TweetDb.where(tag_associada: @parametro).where(hora_extracao: @hora_atual).sort({"retweet":-1}).limit(1)
		
	end

		#ALGORITMOS DA ANALISE DE PADROES E GERAÇÃO DOS GRAFICOS
	def analise_de_padrao_e_sentimentos

		#CONTADOR DE TWEET 
		loc_contador = 0

		#QUANTIDADE DE TWEETS ANALIZADOS
		tweet_contador = 0

		#INICIALIZAÇÃO DO ALGORITMO DE ANALISE DE SENTIMENTOS
		analyzer = Analyzer.new

		#CONJUNTO DE HASHs DOS GRAFICOS		
		localizacao = {"Pais" => "Tweets"}
		cidade = {"Cidades" => "Tweets"}
		idioma =  {"Idioma" => "Tweets"}
		date =  {"Data" => "Tweets"}
		horario = {"Horario" => "Tweets"}
		disposit = {"Tipo de Dispositivo Utilizado" => "Tweets"}
		#HASH DE SENTIMENTOS
		sentimento = {"Sentimento" => "Quantidade" , "Negativo" =>0, "Neutro" =>0, "Positivo" =>0}

		#ANALISE DO TOPO DE BUSCA {ATUAL OU HISTORICA}
		if (@tipo_de_analise == "atual")
			busca = TweetDb.where(tag_associada: @parametro).where(hora_extracao: @hora_atual).limit(@limite_max)
		else
			busca = TweetDb.where(tag_associada: @parametro).limit(@limite_max)
		end

		busca.each do |informacao|

			#CONTADOR DE TWEETS
		  	tweet_contador = tweet_contador + 1

		  	#PARAMETRO DA DATA DE CRIACAO DO TWEETS
		  	d1 = informacao.data

			if date.has_key?(d1) 
    			date[d1] = date[d1] + 1
  			else
  				date[d1] = 1
  			end

  			#PARAMETRO DA HORA DE CRIACAO DO TWEETS
  			d2 = informacao.hora_criacao
  			
  			if horario.has_key?(d2) 
    			horario[d2] = horario[d2] + 1
  			else
  				horario[d2] = 1
  			end

  			#PARAMETRO DOS DISPOSITIVOS
			d3 = informacao.dispositivo

			if disposit.has_key?(d3) 
    			disposit[d3] = disposit[d3] + 1
  			else
  				disposit[d3] = 1
  			end

  			#PARAMETRO DE LOCALIZAÇÃO DO PAIS
  			d4 = informacao.pais

			if(d4.to_s.size > 0)

				loc_contador = loc_contador + 1

			 	if localizacao.has_key?(d4) 
     				localizacao[d4] = localizacao[d4] + 1
  	 			else
  	 				localizacao[d4] = 1
  	 			end
  	 		end

  	 		#PARAMETRO DE LOCALIZAÇÃO DO PAIS
  	 		d5 = informacao.localizacao

  	 		if(d5.to_s.size > 0)
  	 			
  	 			if cidade.has_key?(d5)
  	 				cidade[d5] = cidade[d5] + 1
  	 			else
  	 				cidade[d5] = 1
  	 			end
  	 		end

  	 		#PARAMETRO DE IDIOMA
  			d6 = informacao.idioma

			if idioma.has_key?(d6) 
    			idioma[d6] = idioma[d6] + 1
  			else
  				idioma[d6] = 1
  			end

  			#ANALISE DE SENTIMENTO DOS TWEETS EM INGLÊS
  			if (d6 == "en")
  	
  				d7 = analyzer.process(informacao.tweet)
				
				if(d7.sentiment == ":(")
					sentimento["Negativo"] = sentimento["Negativo"] + 1	
				elsif (d7.sentiment == ":|")
					sentimento["Neutro"] = sentimento["Neutro"] + 1
				elsif (d7.sentiment == ":)")
					sentimento["Positivo"] = sentimento["Positivo"] + 1	
				end
			end
		end
		  
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

	#ALGORITMO DA NUVEM DE PALAVRA
	def nuvem_de_palavras
			
			palavras_comum = File.open('Stop_words.txt','r').read.encode!('UTF-8','UTF-8', :invalid => :replace).split("\n")

			num_palavras = Hash.new(0)

			emoticon = {"😄" => 0 ,"😃" => 0 ,"😀" => 0 ,"😊" => 0 ,"☺️" => 0 ,"😉" => 0 ,"😍" => 0 ,"😘" => 0 ,"😚" => 0 ,"😗" => 0 ,"😙" => 0 ,"😜" => 0 ,"😝" => 0 ,"😛" => 0 ,"😳" => 0 ,"😁" => 0 ,"😔" => 0 ,"😌" => 0 ,"😒" => 0 ,"😞" => 0 ,"😣" => 0 ,"😢" => 0 ,"😂" => 0 ,"😭" => 0 ,"😪" => 0 ,"😥" => 0 ,"😰" => 0 ,"😅" => 0 ,"😓" => 0 ,"😩" => 0 ,"😫" => 0 ,"😨" => 0 ,"😱" => 0 ,"😠" => 0 ,"😡" => 0 ,"😤" => 0 ,"😖" => 0 ,"😆" => 0 ,"😋" => 0 ,"😷" => 0 ,"😎" => 0 ,"😴" => 0 ,"😵" => 0 ,"😲" => 0 ,"😟" => 0 ,"😦" => 0 ,"😧" => 0 ,"😈" => 0 ,"👿" => 0 ,"😮" => 0 ,"😬" => 0 ,"😐" => 0 ,"😕" => 0 ,"😯" => 0 ,"😶" => 0 ,"😇" => 0 ,"😏" => 0 ,"😑" => 0 ,"😺" => 0 ,"😸" => 0 ,"😻" => 0 ,"😽" => 0 ,"😼" => 0 ,"🙀" => 0 ,"😿" => 0 ,"😹" => 0 ,"😾" => 0 ,"🙈" => 0 ,"🙉" => 0 ,"🙊" => 0 ,"💩" => 0 ,"💤" => 0 ,"👅" => 0 ,"👄" => 0 ,"👍" => 0 ,"👎" => 0 ,"👌" => 0 ,"👊" => 0 ,"✊" => 0 ,"✌️" => 0 ,"👋" => 0 ,"✋" => 0 ,"👐" => 0 ,"👆" => 0 ,"👇" => 0 ,"👉" => 0 ,"👈" => 0 ,"🙌" => 0 ,"🙏" => 0 ,"☝️" => 0 ,"👏" => 0 ,"💪" => 0 ,"💛" => 0 ,"💙" => 0 ,"💜" => 0 ,"💚" => 0 ,"❤️" => 0 ,"💔" => 0 ,"💗" => 0 ,"💓" => 0 ,"💕" => 0 ,"💖" => 0 ,"💞" => 0 ,"💘" => 0 ,"💋" => 0 ,"💭" => 0}
						
			if (@tipo_de_analise == "atual")
				busca = TweetDb.where(tag_associada: @parametro).where(hora_extracao: @hora_atual)
			else
				busca = TweetDb.where(tag_associada: @parametro)
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
					
					elsif(palavra == @parametro.downcase)
					
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

	#ALGORITMO APRIORI DE MINERAÇÃO
	def mineracao_apriori

		dados = []
		dados2 = []
		dados3 = []

		if (@tipo_de_analise == "atual")
			busca = TweetDb.where(tag_associada: @parametro).where(hora_extracao: @hora_atual)
		else
			busca = TweetDb.where(tag_associada: @parametro)
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

  		if (miner.pais != "")
			tg3 = miner.pais #pegando primeiro parametro para a mineração 
			tg4 = miner.dispositivo #pegando segundo parametro para a mineração

			item2 =  Array.new
			item2.push(tg3)
			item2.push(tg4)

  			dados2.push(item2)
  		else
  		end

  		#terceiro conjunto de paramentros do apriori


		tg5 = miner.criador #pegando primeiro parametro para a mineração
		tg6 = miner.data #pegando segundo parametro para a mineração

		item3 =  Array.new
		item3.push(tg5)
		item3.push(tg6)

  		dados3.push(item3)

		end
		
		#analise do data e hora

		support = 10
	 	confidence = 20
		item_set = Apriori::ItemSet.new(dados)
	 	variavel = item_set.mine(support, confidence)
	 	$mining = variavel.to_a

	 	#analise do pais e dispositivo

	 	support = 10
	 	confidence = 20
	 	item_set2 = Apriori::ItemSet.new(dados2)
	 	variavel2 = item_set2.mine(support, confidence)
	 	$mining2 = variavel2.to_a
	end
end

#################################################################################
class Analyzer
	def initialize
    	Sentimentalizer.setup
  	end

  	def process(phrase)
    	Sentimentalizer.analyze phrase
  	end
end