extends Node2D

const SLICE_NAMES = [
	"Patty",
	"Tomato",
	"Lettuce"
]

const BLOCK_RED := 3
const BLOCK_WHITE := 2
const EMPTY_RED := 5
const EMPTY_WHITE := 4

onready var tm := $TileMap

# Ui elements
onready var reciept_label := $UI/OrderReceipt/Label
onready var reciept := $UI/OrderReceipt
onready var fail_prompt := $UI/LevelFailedPrompt

export(int) var patty_count : int
export(int) var tomato_count : int
export(int) var lettuce_count : int
export(int) var onion_count : int
export(int) var cheese_count : int

# What slices do we need to win the level?
var required_slice_count : Array

# Store which slices the player has already grabbed
var collected_slice_count : Array

# Set true when the player is able to exit the level!
var ready_to_finish : bool


var toggle_blocks_active : bool = false # By default, RED blocks are solid and WHITE blocks are hollow
var red_block_cells : Array
var white_block_cells : Array


signal level_restart

func _ready() -> void:
	# Find all switchable blocks
	red_block_cells = tm.get_used_cells_by_id(BLOCK_RED)
	white_block_cells = tm.get_used_cells_by_id(EMPTY_WHITE)
	
	# Build required slice array
	required_slice_count = [patty_count,tomato_count,lettuce_count,onion_count,cheese_count]
	
	# Create order
	reciept_label.text = "Order:"
	for i in range(required_slice_count.size()):
		if required_slice_count[i] > 0:
			reciept_label.text += "\n%s x%d" % [SLICE_NAMES[i],required_slice_count[i]]
		# Populate collected slice array
		collected_slice_count.append(0)
	
	reciept.rect_size = reciept_label.rect_size + Vector2.RIGHT*4


func _input(event:InputEvent) -> void:
	# Restart the level
	if event.is_action_pressed("restart"):
		restart_level()

# Reset everything to it's initial state
func restart_level() -> void:
	# Enable all pickups
	for slice in get_tree().get_nodes_in_group("Pickup"):
		slice.sprite.visible = true
	# Reset blocks
	if toggle_blocks_active: flip_toggle_blocks()
	# Reset UI
	fail_prompt.visible = false
	
	# Reset grabbed slices list
	for i in range(collected_slice_count.size()):
		collected_slice_count[i] = 0
	
	emit_signal("level_restart")


# Called when the player grabs a slice
func on_player_slice_collected(index):
	collected_slice_count[index] += 1
	# If we grabbed a slice we didn't need, we fail the level - show a prompt to restart
	if required_slice_count[index] < collected_slice_count[index]:
		fail_prompt.visible = true
	else:
		# Determine if we're ready to complete
		ready_to_finish = true
		for i in range(collected_slice_count.size()):
			if collected_slice_count[i] != required_slice_count[i]:
				ready_to_finish = false
				break


# Called when the player reaches the level goal
func on_player_reach_goal() -> void:
	# Check if we're ready
	if ready_to_finish:
		print("Level complete!")
	else:
		print("Missing or extra slices!")


# Call to flip white and red block states
func flip_toggle_blocks() -> void:
	
	# Toggle variable
	toggle_blocks_active = not toggle_blocks_active
	
	# Figure out what we want to switch to
	var white_target = BLOCK_WHITE if toggle_blocks_active else EMPTY_WHITE
	var red_target = EMPTY_RED if toggle_blocks_active else BLOCK_RED
	
	# Replace tiles
	for cell in red_block_cells:
		tm.set_cellv(cell,red_target)
	for cell in white_block_cells:
		tm.set_cellv(cell,white_target)
