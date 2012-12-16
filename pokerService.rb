require 'sinatra'
require "sinatra/reloader" if development?
require 'mongo_mapper'
require 'json'

class User
	include MongoMapper::Document

	key :email, String, :required => true
	key :firstName, String
	key :lastName, String
end

class Game
	include MongoMapper::Document

	key :date, Time
	key :maxPlayers, Integer
	key :userIds, Array
	many :users, :in => :user_ids
end

#######################################################

before do
	if request.request_method == "POST" and request.content_type=="application/json"
		body_parameters = request.body.read
		parsed = body_parameters && body_parameters.length >= 2 ? JSON.parse(body_parameters) : nil
		params.merge!(parsed)
	end
end

configure do
	mongo_uri = ENV['connectionString']
	MongoMapper.connection = Mongo::MongoClient.from_uri(mongo_uri)
	MongoMapper.database = ENV['databaseName']
end

#######################################################

get "/games" do
	Game.all.to_json
end

get "/users" do
	@params = CGI::parse(request.query_string)

	if @params.has_key?("email")
		user = User.first(:email => @params["email"])
		user.to_json
	else
		User.all.to_json
	end
end

get "/user/:id" do
	@user = User.first(:id => "#{params[:id]}")
	@user.to_json
end

put "/user/:id" do
	@user = User.first(:id => session[:user])
	@user.set(:firstName => params[:firstName])
	@user.set(:lastName => params[:lastName])
end

get "/game/:id" do
	game = Game.find("#{params[:id]}")
	@playerIds = game.userIds
	@players = []
	@playerIds.each do |playerId|
		@players << User.find(playerId)
	end
	@players.to_json
end

put "/user/:userId/game/:gameId" do
	game = Game.find("#{params[:gameId]}")
	if (game.userIds.length < game.maxPlayers)
		game.push_uniq(:userIds => "#{params[:userId]}")
	else
		halt({ :error => "Sorry but the game is full!" }.to_json)
	end
	{ :message => "Successfully signed up for game" }.to_json
end

delete "/user/:userId/game/:gameId" do
	game = Game.find("#{params[:gameId]}")
	game.pull(:userIds => "#{params[:userId]}")
	{ :message => "Successfully removed user from game" }.to_json
end

post "/game" do
	game = Game.create({
		:date => Time.local("#{params[:year]}", "#{params[:month]}", "#{params[:day]}", "#{params[:hour]}", "#{params[:min]}"),
		:maxPlayers => "#{params[:maxPlayers]}"
	})
	if game.save
		{ :message => "Successfully created game with id #{game.id}" }.to_json
	else
		{ :error => "Problem creating game" }.to_json
	end
end
