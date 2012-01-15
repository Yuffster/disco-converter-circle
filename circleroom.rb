# Extracts all relevant room details from CircleMUD .wld files.
# 
# It's CircleRoom instead of DikuRoom because it supports alphabetic bitwise
# operators, but it should work with DikuMUD world files just as well.
#
# @author Michelle Steigerwalt <msteigerwalt.com>
# @copyright 2010 Michelle Steigerwalt
class CircleRoom

	# Match order:
	#     Room number ^#(\d+)
	#     Title Line
	#     Description Line (multiline, ends with ~)
	#     Room Code Line (zone number, bit vector, sector type)
	#     Exits - Everyting up to a capital S on its own line.
	@@pattern    = /^#(\d+)\s+([^\n]*?)~\s([^~]*?)~\s([^\n]*?)\s(.*)/m
	@@room_types = ['inside','city','field','forest','hills','mountain',
	                'water','water_noswim', 'flying', 'underwater']
	@@directions = ['north', 'east', 'south', 'west', 'up', 'down']

	attr_accessor :id, :zone_id, :short, :long, :type, :items, :exits,
	              :codebase

	def initialize()

		@exits = []
		@items = []

		# Pretty much just here so the template has access to the info.
		# TODO: Move it somewhere better.
		@codebase = 'CircleMUD or DikuMUD-compatible'

	end

	# Takes a full *.wld file and parses it into individual rooms.
	def self.parse_wld(wld)

		rooms = []

		room_data = wld.split(/\nS\n/)
		room_data.each do |data|
			rooms << load_room(data)
		end

		rooms.compact

	end

	def self.load_room(raw)

		if raw.match(/\$\n/) 
			return nil
		end

		# Ridiculous tilde escape.  I'm ashamed of these lines.
		tilde_esc = "{{Tilde escaped by "+__FILE__.split('/').pop+"}}"
		raw = raw.gsub(/~[^\n]/, tilde_esc)

		# Get the data from running the raw room text through our regex.
		room = self.new()
		data = raw.scan(@@pattern).shift
		
		# Let the user know about our failure.
		if !data
			puts "FAIL (complete): "
			puts "====> "+raw
			return nil
		end
		
		#Unescape tildes.  Again, shame.
		data = data.map { |l| l.gsub(tilde_esc, '~') }

		# Probably should move the escaping to something more template-specific
		# at a later date.
		room.id    = data.shift.gsub('"', '\\\\"')
		room.short = data.shift.gsub('"', '\\\\"')
		room.long  = data.shift.gsub('"', '\\\\"')
		room.long  = room.long.gsub(/\n/, ' ').gsub(/\s+/, ' ').strip

		# Lines and codes are parsed separately.
		room.parse_codes (data.shift)
		room.parse_extras(data.shift)

		room

	end

	def parse_codes(line)

		codes = line.split(/\s/)

		@zone_id   = codes.shift

		# TODO: We should at least add light support for dark rooms.
		@bitvector  = codes.shift

		@type       = @@room_types[codes.shift.to_i]

	end

	def parse_extras(raw)
			
		# Alright, I'm not too hip to the specifics of the Ruby regex engine
		# yet, so I'm doing this silly split operation.
		#
		# DON'T JUDGE ME.
		delim  = "q234qwe&{{raSd%$f\n"
		extras = raw.gsub(/^(D\d|E)\n/, "#{delim}\\1\n").split(delim)
		extras.shift # Delete the first item of the array, which is empty.

		# Go through the list, determine which extras are items and which are
		# exits.  Handle each type accordingly.
		extras.each do |extra|
			lines = extra.split("\n")
			if lines[0].match(/^D\d/)
				parse_exit(extra)
			elsif lines[0].match('E')
				parse_item(extra)
			end
		end

	end

	def parse_exit(raw)

		lines = raw.split("\n")

		# Figure out the direction
		dir       = lines.shift.match(/D(\d+)/)[1].to_i
		direction = @@directions[dir]

		if !direction
			puts "FAIL ["+id+"] (EXIT: dir): "+raw.gsub("\n", "\\n")
			puts "["+data.inspect+"]"
			return nil
		end

		# Pattern is description, then door keywords, then codes.
		pattern = /([^~]*?)\s?~\s([^~]*?)~\s?(.*?)$/m

		nraw = lines.join("\n")
		data = nraw.scan(pattern).shift

		if !data
			puts "FAIL ["+id+"] (EXIT: data): "
			puts "====> "+nraw
			return nil
		end

		description   = data.shift
		door_keywords = data.shift
		codes         = data.shift.split(/\s/)

		# Currently, Disco doesn't support doors, so we'll just ignore these
		# bits for now.
		door_flag     = codes.shift
		key_number    = codes.shift

		# The exit room.
		room          = codes.shift

		add_exit(direction, room)
		
	end

	def parse_item(raw)

		# Pattern is keywords on one line followed by a long description.
		pattern = /(.*)\s?~\s+([^~]*)/m

		lines = raw.split("\n")
		lines.shift
		data = lines.join("\n").scan(pattern).shift

		if !data
			puts "FAIL ["+id+"] (ITEM): "
			puts "====> "+nraw
			return nil
		end

		add_item(data.shift, data.shift)

	end

	def add_exit(direction, room)
		@exits << {'direction' => direction, 'room' => room}
	end

	def add_item(adjs, desc)
		@items << {
			'keywords' => adjs,
			'description' => desc.gsub("\n", "\\n").gsub('"', '\\\\"')
		}
	end

	# Takes the list of all rooms and expands the exits (ie, 1.js becomes
	# 0001-The_Void.js).
	#
	# TODO: Fill out this method.
	def expand_exits(index)
		@exits.each do |ex|
			id = ex['room']
			if index[id] 
				ex['room'] = index[id].expand_id
			end
		end
	end

	def get_directory
		("%04d" % @zone_id) + "/"
	end

	def expand_id
		get_directory()+@short.gsub(/[^\w]+/, '_')
	end

	def get_binding
		binding
	end

end
