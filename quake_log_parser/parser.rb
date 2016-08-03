@regexKill = /[0-9]{1,2}:[0-9]{1,2}\sKill:\s((?<id_killer>[0-9])+\s)((?<id_dead>[0-9])+\s)((?<id_reason>[0-9])+):(?<killer_name>.*(?=killed))killed(?<dead_name>.*(?=by))by\s(?<death_reason>([A-Z_])+)/
@regexClientUserinfoChanged =  /[0-9]{1,2}:[0-9]{1,2}\sClientUserinfoChanged:\s((?<id_user>[0-9])+\s)n\\(?<user_name>.*(?=\\t\\))/
@regexInitGame =  /[0-9]{1,2}:[0-9]{1,2}\s(InitGame):\s/

@gameHash = nil
@gamePlayers = Hash.new

# Task 1
def parserMethod
	games = Hash.new
	count = 1

	File.open('games.log', 'r') do |f|
		f.each_line do |line|
			# Analise de inicio de um novo jogo
			unless line.match(@regexInitGame).nil?
				unless @gameHash.nil?
					games.store("game_#{count}", @gameHash)
					count += 1

					@gamePlayers.clear
				end

				@gameHash = Hash["total_kills" => 0, "players" => Array.new, "kills" => Hash.new]
				next
			end

			# Analise da entrada de um jogador ou a alteracao de seu nome
			match = line.match(@regexClientUserinfoChanged)
			unless match.nil?
				if @gamePlayers.key?(match['id_user']) && @gamePlayers[match['id_user']] == match['user_name']
					next
				elsif @gamePlayers.key?(match['id_user']) && @gamePlayers[match['id_user']] != match['user_name']
					playerKills = @gameHash["kills"][@gamePlayers[match['id_user']]]

					@gameHash["kills"].delete(@gamePlayers[match['id_user']])
					@gameHash["kills"].store(match['user_name'], playerKills)

					idx = @gameHash["players"].index(@gamePlayers[match['id_user']])
					@gameHash["players"][idx] = match['user_name']

					@gamePlayers[match['id_user']] = match['user_name']
					next
				end

				insertPlayerGame(match['id_user'], match['user_name'].strip)
				next
			end	

			# Analise da ocorrencia de kills
			match = line.match(@regexKill)
			unless match.nil?
				@gameHash["total_kills"] += 1

				if match["killer_name"].strip.eql? match["dead_name"].strip
					next
				end	

				if match["killer_name"].strip.eql? "<world>"
					if @gameHash["kills"][match["dead_name"].strip].nil?
						insertPlayerGame(match["id_dead"].strip, match["dead_name"].strip)
					end	
					
					@gameHash["kills"][match["dead_name"].strip] -= 1
				else
					if @gameHash["kills"][match["killer_name"].strip].nil?
						insertPlayerGame(match["id_killer"].strip, match["killer_name"].strip)
					end

					@gameHash["kills"][match["killer_name"].strip] += 1
				end
			end
		end
	end
	games.store("game_#{count}", @gameHash)

	return games
end

# Task 2
def rankingMethod
	players = Hash.new

	@parserResult = parserMethod

	@parserResult.each do |key, value|
		value["kills"].each do |k, v|
			unless players.key?(k)
				players.store(k, 0)
			end

			players[k] += v
		end
	end

	return players
end

# Task 3
def parserReasonsMethod
	games = Hash.new

	reasonsDeath = nil
	count = 1

	File.open('games.log', 'r') do |f|
		f.each_line do |line|
			# Analise do inicio de um novo jogo
			unless line.match(@regexInitGame).nil?
				unless reasonsDeath.nil?
					games.store("game_#{count}", reasonsDeath)
					count += 1
				end

				reasonsDeath = Hash.new
				next
			end

			# Analise da ocorrencia de kills
			match = line.match(@regexKill)
			unless match.nil?
				unless reasonsDeath.key?(match["death_reason"])
					reasonsDeath.store(match["death_reason"], 0)
				end
				reasonsDeath[match["death_reason"]] += 1
			end
		end
	end
	games.store("game_#{count}", reasonsDeath)

	return games
end

# Insere um novo usuario no game
def insertPlayerGame(id_user, user_name)
	@gamePlayers.store(id_user, user_name)
	@gameHash["players"] << user_name
	@gameHash["kills"].store(user_name, 0)
end

# Impressao de relatorio com ranking de kills e causas de morte
puts "RANKING:"
rankingMethod.sort_by{|player, kills| kills}.reverse.each do |player, kills|
	puts "PLAYER #{player} #{kills} KILLS"
end

@parserResult.each do |game, gamesHash|
	puts game
	gamesHash["kills"].sort_by{|player, kills| kills}.reverse.each do |player, kills|
		puts "PLAYER #{player} #{kills} KILLS"
	end	
end	

puts "MEANS OF DEATH BY GAME:"
parserReasonsMethod.each do |game, reasonsHash|
	puts game
	reasonsHash.sort_by{|reason, quantity| quantity}.reverse.each do |reason, quantity|
		puts "#{reason} #{quantity}"
	end	
end