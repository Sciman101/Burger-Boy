extends Node2D

# Reference to tile data used for the editor
# This keeps track of:
# - The position in the tilemap texture used for rendering the preview (This is multiplied by 16)
# - The actual tile we need to place down
# - The tile index used for building the level
const TILE_DATA = [
	{"tilemap_pos":Vector2(3,3),"editor_tile":0,"level_tile":1}, # Autotile
	{"tilemap_pos":Vector2(9,4),"editor_tile":1,"level_tile":2}, # One way platform
	{"tilemap_pos":Vector2(0,5),"editor_tile":6,"level_tile":3}, # Start
	{"tilemap_pos":Vector2(1,5),"editor_tile":7,"level_tile":4}, # Goal
	{"tilemap_pos":Vector2(1,4),"editor_tile":3,"level_tile":5}, # Red toggle block
	{"tilemap_pos":Vector2(2,4),"editor_tile":4,"level_tile":6}, # White toggle block
	{"tilemap_pos":Vector2(10,0),"editor_tile":13,"level_tile":7}, # Switch
]
const TILEMAP_SIZE := Vector2(20,12)

# Tilemap used for placing editor tiles - this tilemap is NOT USED for actual gameplay
onready var editor_tm := $EditorTilemap
# Level instance used to build the level for testing purposes. This DOES have collisions and everything
onready var editor_level := $EditorLevel
onready var cursor := $CursorPreview
onready var particles := $PlacementParticles

# Array used to hold level data in tile form to make conversion easier
var level_tile_data := [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]

var selected_tile := 0
var cursor_pos := Vector2.ZERO
var is_playing := false

# Move the cursor and such
func _input(event:InputEvent) -> void:	
	
	if event.is_action("editor_play") and event.is_pressed():
		
		is_playing = not is_playing
		
		editor_tm.visible = not is_playing
		editor_level.visible = is_playing
		cursor.visible = not is_playing
		
		editor_level.destroy_level()
		
		if is_playing:
			# Actually play the level
			var code = generate_level_code()
			editor_level.generate_level(code)
	
	elif is_playing:
		return
	
	elif event.is_action("editor_next") or event.is_action("editor_prev"):
		selected_tile += sign(event.get_action_strength("editor_next") - event.get_action_strength("editor_prev"))
		selected_tile = wrapi(selected_tile,0,TILE_DATA.size())
		
		cursor.region_rect.position = get_selected_tile().tilemap_pos*16
	
	elif event is InputEventMouseMotion:
		cursor_pos = (get_global_mouse_position()-Vector2(8,8)).snapped(Vector2.ONE*16)
		var p = cursor.position
		cursor.position = cursor_pos
		if p != cursor.position:
			# Try and place/remove blocks
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				place_tile_at_cursor(get_selected_tile().editor_tile,get_selected_tile().level_tile)
			elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
				place_tile_at_cursor(-1,0)
	
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			place_tile_at_cursor(get_selected_tile().editor_tile,get_selected_tile().level_tile)
		elif event.button_index == BUTTON_RIGHT:
			place_tile_at_cursor(-1,0)

func place_tile_at_cursor(tile:int,level_tile:int) -> void:
	
	var p = cursor_pos/16
	var index = p.x + p.y * TILEMAP_SIZE.x
	
	if tile != -1:
		# If placing a start or goal, remove other occurances of it
		if tile == 6 or tile == 7:
			var others = editor_tm.get_used_cells_by_id(tile) 
			for tile in others:
				editor_tm.set_cellv(tile,-1)
				level_tile_data[tile.x+tile.y*TILEMAP_SIZE.x] = 0
		# Play particle effect
		particles.restart()
		particles.position = cursor_pos + Vector2(8,8)
		particles.emitting = true
	
	# Place the tile
	editor_tm.set_cellv(cursor_pos/16,tile)
	level_tile_data[index] = level_tile


# Quick getter for the currently selected tile
func get_selected_tile() -> Dictionary:
	return TILE_DATA[selected_tile]


# Create a level code string for use in the level node
func generate_level_code() -> String:
	var result := "000000"
	for tile in level_tile_data:
		result += Global.HEX[tile]
	return result
