require "erb"
# Converts a given Room object to a Disco-compatible JavaScript class
# file.
#
# Room objects must have the following properties:
# 
#    id    (mixed)  : Numeric ID or unique string related to the room
#    short (string) : short description (room title)
#    long  (string) : full room description
#    type  (string) : Optional, the type of room (inside, outside, etc)
#    items (array)  : Array of hashes containing description item keywords
#                     and descriptions. [keywords, description]
#    exits (array)  : Array of hashes containing exit directions and room
#                     IDs to lead to. [direction, room]
#                     TODO: Door support.
#
#  To generate a room, pass a room object to the generate_disco method.
#
# @author Michelle Steigerwalt <msteigerwalt.com>
# @copyright 2010 Michelle Steigerwalt
class RoomGenerator

	# The method name sounds a lot cooler than what it actually does.
	def self.output_disco(room)
		template = File.open("room.js.erb").read
		ERB.new(template).result(room.get_binding)
	end

end
