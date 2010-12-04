#!/usr/bin/env ruby

# This script takes DikuMUD/CircleMUD-formatted zone files and converts them to
# a format compatible with the Disco mudlib.
#
# NOTE: Please ensure that you follow all original license requirements of
#       converted areas and give credit to the original authors.
#
# For complete instructions, run the script with no arguments.
#
# @author Michelle Steigerwalt <msteigerwalt.com>
# @copyright 2010 Michelle Steigerwalt

require "circleroom"
require "roomgenerator"

# Command-line documentation of arguments.
unless ARGV.length == 2 || ARGV.length == 3
	puts "Usage: ./"+ __FILE__ +" <source directory> <output directory> <optional: zone ID>"
	puts ""
	puts "Example (will output all rooms in circle-3.1/world to rooms/):"
	puts "./"+__FILE__+" circle-3.1/world rooms/"
	puts ""
	puts "Example (will output all rooms in zone 30 from circle-3.1/world/wld/30.wld to rooms/):"
	puts "./"+__FILE__+" circle-3.1/world/ rooms/ 30"
	exit
end

# Fun configuration options!
root_path   = Dir.getwd
source_path = ARGV.shift.gsub(/\/$/, '')
output_path = ARGV.shift.gsub(/\/$/, '')
zone = ARGV.shift 

zones = []
if zone
	zones = [zone]
else
	# If zone isn't specified, look in the wld directory for all zones.
	Dir.chdir(source_path+'/wld/')
	Dir.glob("*.wld"){ |zone| zones << zone.match(/(.*)\.wld/)[1] }
	Dir.chdir(root_path)
end

# Open each zone's wld file, extract all the room objects, then output in Disco
# format.
zones.each do |zone|
	rooms = []
	wld   = File.open(source_path+"/wld/#{zone}.wld").read
	rooms.concat(CircleRoom.parse_wld(wld))
	rooms.each do |room|
		# Convert the room file into JavaScript
		code = RoomGenerator.output_disco(room)
		# Save to rooms/<number>.js
		file = File.open(output_path+'/'+room.id+'.js', 'w') {|f| f.write(code)}
	end
	puts "LOAD COMPLETE: Zone "+zone
end

puts "Finished loading all zones."
