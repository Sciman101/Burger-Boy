extends Node

const LEVEL_VERSION : int = 0

const ORD_0 = ord('0')

# Names of slices
const SLICE_NAMES = [
	"Patty",
	"Tomato",
	"Lettuce",
	"Onion",
	"Cheese"
]

func hexcorrect(c:int) -> int:
	if c <= 57:
		return c - 48
	else:
		return c - 97


func compress_level_data(leveldat:String) -> String:
	var ascii = leveldat.to_ascii()
	var dat = PoolByteArray()
	
	# Convert hex code into base 64
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
	var start : int = 0
	var tracked_char : int = -1
	for i in range(0,123):
		var c = b64.ord_at(i)
		if c != tracked_char:
			
			if i - start > 3:
				final += "-%d%s" % [i-start,char(tracked_char)]
			else:
				final += b64.substr(start,i-start)
			
			start = i
			tracked_char = c
	
	# Spit out the final level code
	return final


# Decompress a compressed level data string back into hex code
func decompress_level_data(compleveldat:String) -> String:
	
	var size = compleveldat.length()
	
	var b64 := ""
	for i in range(size):
		if compleveldat.ord_at(i) == 45: # Hypen
			var start := i+1
			var end := start+1
			# Determine where the compressed chunk ends
			
			# TODO add what i described up there
			
			# Add chunk
			b64 += char(c).repeat(int(compleveldat.substr(start,end)))
			i = end
		else:
			b64 += compleveldat.substr(i,1)
	
	return b64
