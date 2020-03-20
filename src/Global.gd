extends Node

const LEVEL_VERSION : int = 0

const ORD_0 := ord('0')
const ORD_DASH := ord('-')

# Names of slices
const SLICE_NAMES = [
	"Patty",
	"Tomato",
	"Lettuce",
	"Onion",
	"Cheese"
]

const B64 = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/']


# Convert an ASCII code to a hex code
func hexcorrect(c:int) -> int:
	if c <= 57:
		return c - 48
	else:
		return c - 87 # Add 10


# Convert a hex code to a character
func hexchar(c:int) -> String:
	if c <= 9:
		return char(c+48)
	else:
		return char(c+87)


# Turn a full hex level code ino a compressed B64 variant
func compress_level_data(leveldat:String) -> String:
	var ascii = leveldat.to_ascii()
	var dat = PoolByteArray()
	
	# Convert hex code into byte array, so it can be easier turned into base64
	for i in range(0,246,2):
		var byte = (hexcorrect(ascii[i]) << 4) | hexcorrect(ascii[i+1])
		dat.append(byte)
	
	# Convert to base 64
	var b64 = Marshalls.raw_to_base64(dat)
	
	var final : String = ""

	# Remove any characters that appear more than 3 times
	# Format: ,xc
	# Where 'x' is the number of occurances of that character
	# And 'c' is the character in question
	# This is just to reduce the size of the string even further
	var start : int = 0
	var tracked_char : int = -1
	for i in range(b64.length()+1):
		var c = b64.ord_at(i)
		if c != tracked_char or i - start >= 64:

			if i - start > 3:
				# Get count as base 64
				final += "-%s%s" % [B64[i-start],char(tracked_char)]
			else:
				final += b64.substr(start,i-start)

			start = min(i,start+64)
			tracked_char = c
	
	# Spit out the final level code
	return final


# Decompress a compressed level data string back into hex code
func decompress_level_data(compleveldat:String) -> String:
	
	var decompressed := ""
	
	# Take the level data and uncompress the repeated characters so the marshalls library can convert it back to raw data
	var ascii := compleveldat.to_ascii()
	var i := 0
	while i < ascii.size():
		if ascii[i] == ORD_DASH:
			var count = B64.find(char(ascii[i+1]))
			var block = char(ascii[i+2])
			decompressed += block.repeat(count)
			i += 2
		else:
			decompressed += char(ascii[i])
		i += 1
	
	var result := ""
	# Convert base64 code back into a byte array
	var raw := Marshalls.base64_to_raw(decompressed)
	# Take btye array and convert into hex code, so the level generator can parse it easier
	for i in range(raw.size()):
		var byte = raw[i]
		result += hexchar((byte >> 4) & 15)
		result += hexchar(byte & 15)
	
	return result
