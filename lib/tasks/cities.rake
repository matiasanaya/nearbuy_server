task :map_missing => :environment do
	missing_count = Missing.count
	if missing_count == 0
		puts 'Everything up-to date :)'
	else
		puts "Task will map #{missing_count} entries"
		Missing.all.each do |missing|
			puts missing.search
			city = City.new(:search => missing.search, :name => missing.name)
			bool1 = city.save
			bool2 = missing.destroy ? true : false
			puts (bool1 && bool2)
		end
		if Missing.count == 0
			puts 'All done :)'
		else
			puts 'Something went wrong :('
		end
	end
end