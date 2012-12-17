require 'mongo'
include Mongo

mongo_uri = ENV['connectionString']
@client = MongoClient.from_uri(mongo_uri)
@db = @client.db(ENV['databaseName'])
@users = @db.collection('users')

begin
	file = File.new("emails.txt", "r")
	while (line = file.gets)
		user = "#{line}".chomp.split('#')
		new_user = { :email => user[0].downcase, :firstName => user[1], :lastName => user[2], :created_on => Time.now }
		@users.insert(new_user)
	end
	file.close
rescue => err
    	puts "Exception: #{err}"
    	err
end

puts "All done!"
