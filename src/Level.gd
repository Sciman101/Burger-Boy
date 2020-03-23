extends Node2D

# Lookup used for converting from level code to tilemap
const BLOCK_LOOKUP = [
	-1,
	0,
	1,
	preload("res://assets/scenes/partial/Player.tscn"),
	preload("res://assets/scenes/partial/Goal.tscn"),
	3,
	4,
	preload("res://assets/scenes/partial/SwitchBlock.tscn"),
	-2, # Unused
	-2 # Unused
]

# Tile IDs for toggle blocks
const BLOCK_RED := 3
const BLOCK_WHITE := 2
const EMPTY_RED := 5
const EMPTY_WHITE := 4

# Reference to tilemaps
onready var tm := $TileMap
# Parent for all instances - this includes slices and players and goals
onready var inst_parent := $Instances
onready var toggle_parent := $ToggleSwitch

# Ui elements
onready var reciept_label := $UI/OrderReceipt/Label
onready var reciept := $UI/OrderReceipt
onready var fail_prompt := $UI/LevelFailedPrompt

# Level code
export(String,MULTILINE) var level_code : String

export(int) var patty_count : int
export(int) var tomato_count : int
export(int) var lettuce_count : int
export(int) var onion_count : int
export(int) var cheese_count : int

# What slices do we need to win the level?
var required_slice_count : Array

# Store which slices the player has already grabbed
var collected_slice_count : Array = [0,0,0,0,0]

# Set true when the player is able to exit the level!
var ready_to_finish : bool

# Used for toggle blocks
var toggle_blocks_active : bool = false # By default, RED blocks are solid and WHITE blocks are hollow
var red_block_cells : Array
var white_block_cells : Array
var switch_sprites : Array

signal level_restart
signal on_level_completed

func _ready() -> void:
	
	# Generate level
	if level_code.length() > 0:
		if level_code.length() == 246:
			generate_level(level_code)
			
			var comp = Global.compress_level_data(level_code)
			print(comp)
			print(Global.decompress_level_data(comp))
		else:
			print("Warning: Invalid level code!")


func _input(event:InputEvent) -> void:
	# Restart the level
	if event.is_action_pressed("restart"):
		restart_level()


# Generate the level based on the provided level code
func generate_level(code:String) -> void:
	
	var data = code.to_ascii()
	
	# Determine if we're using the correct level format
	if Global.hexcorrect(data[0]) != Global.LEVEL_VERSION:
		print("Error: Invalid level format")
		return
	
	# Determine slice count
	patty_count = Global.hexcorrect(data[1])
	tomato_count = Global.hexcorrect(data[2])
	lettuce_count = Global.hexcorrect(data[3])
	onion_count = Global.hexcorrect(data[4])
	cheese_count = Global.hexcorrect(data[5])
	
	# Assemble tilemap
	tm.clear()
	var pos : Vector2
	
	for c in range(6,246):
		var indx = Global.hexcorrect(data[c])
		# Figure out what we're doing
		if indx <= 9:
			# Place tile
			var block = BLOCK_LOOKUP[indx]
			if block is int:
				# Set tilemap
				tm.set_cellv(pos,block)
			else:
				# Spawn instance
				var inst = block.instance()
				if indx != 7:
					inst_parent.add_child(inst)
				else:
					toggle_parent.add_child(inst)
					switch_sprites.append(inst.get_node("Sprite"))
				inst.position = pos * 16 + Vector2.ONE*8
		
		# Update position
		pos.x += 1
		if pos.x >= 20:
			pos.x = 0
			pos.y += 1
	
	# Find all switchable blocks
	red_block_cells = tm.get_used_cells_by_id(BLOCK_RED)
	white_block_cells = tm.get_used_cells_by_id(EMPTY_WHITE)
	
	# Build required slice array
	required_slice_count = [patty_count,tomato_count,lettuce_count,onion_count,cheese_count]
	
	# Update the label showing the order
	update_order_desc()


func update_order_desc() -> void:
	# Create order description
	reciept_label.text = "Order:"
	for i in range(required_slice_count.size()):
		if required_slice_count[i] > 0:
			reciept_label.text += "\n%s %d/%d" % [Global.SLICE_NAMES[i],collected_slice_count[i],required_slice_count[i]]
	reciept.rect_size = reciept_label.rect_size + Vector2.RIGHT*4


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
	
	update_order_desc()
	
	emit_signal("level_restart")


# Used to clear all instances and tilemap data for the level
# This is only really used by the editor for when we regenerate the level
func destroy_level() -> void:
	tm.clear()
	for child in inst_parent.get_children():
		child.queue_free()
	for button in toggle_parent.get_children():
		button.queue_free()
	switch_sprites.clear()


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
	update_order_desc()


# Called when the player reaches the level goal
func on_player_reach_goal() -> void:
	# Check if we're ready
	if ready_to_finish:
		print("Level complete!")
		emit_signal("on_level_completed")
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
	
	# Flip sprites
	for sprite in switch_sprites:
		sprite.region_rect.position.y = 16 - sprite.region_rect.position.y

# Called when the player enters a flip area
func _on_ToggleSwitch_body_entered(body):
	if body and body.is_in_group("Player"):
		flip_toggle_blocks()
