extends KinematicBody2D

const SLICE = preload("res://assets/scenes/partial/Slice.tscn")

export(float) var move_speed : float
export(float) var jump_height : float
export(float) var jump_time : float

# Where did the player start?
var start_pos : Vector2

# Jumping properties
var jump_speed : float
var gravity : float

# Motion vector
var motion : Vector2

# Array of slices we've collected
var slices = []

# Collision objects
var shape : RectangleShape2D
onready var collider := $CollisionShape2D

onready var animation := $AnimationPlayer

onready var slice_parent := $Slices
onready var sprite := $Sprite
onready var eye_sprite := $Slices/Eyes

onready var tween := $Tween

signal on_slice_collected(index)

func _ready() -> void:
	# Calculate movement parameters
	gravity = jump_height/(jump_time*jump_time)
	jump_speed = sqrt(2 * gravity * jump_height)
	
	# Get collision shape
	shape = shape_owner_get_shape(0,0)
	
	start_pos = position


func _physics_process(delta:float) -> void:
	
	var hor_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	# Handle visuals
	if hor_input != 0:
		# Movement animation and flip sprites
		animation.play("Walk")
		var flip = sign(hor_input) != 1
		sprite.flip_h = flip
		eye_sprite.flip_h = flip
	else:
		# Idle animation
		animation.play("Idle")
	
	# Approach target motion
	motion.x = lerp(motion.x,hor_input*move_speed,delta*10)
	
	# Gravity and jumping
	if is_on_floor():
		motion.y = 0
		if Input.is_action_just_pressed("jump"):
			motion.y = -jump_speed
	motion.y += gravity * delta
	
	# Actually move
	# warning-ignore:return_value_discarded
	motion = move_and_slide(motion,Vector2.UP)


func restart() -> void:
	motion = Vector2.ZERO
	position = start_pos
	sprite.flip_h = false
	eye_sprite.flip_h = false
	
	tween.stop_all()
	
	# Clear all slices
	slices.clear()
	for node in slice_parent.get_children():
		if node != eye_sprite:
			node.queue_free()
	eye_sprite.position = Vector2(0,-3)
	
	# Reset collisions
	shape.extents.y = 6
	collider.position.y = -2


# Add a new slice to the stack
func add_slice(index:int) -> void:
	slices.append(index)
	
	# Create slice visual
	var inst = SLICE.instance()
	inst.frame = index
	# Add to player
	slice_parent.add_child(inst)
	
	var pos = Vector2(0,-2+(slices.size()-1)*-4)
	inst.position = pos
	slice_parent.move_child(eye_sprite,slices.size())
	
	# Move top bun and new slice
	tween.seek(0.25)
	tween.stop_all()
	tween.interpolate_property(eye_sprite,"position",eye_sprite.position,pos + Vector2.UP*6,0.25,Tween.TRANS_BACK,Tween.EASE_OUT)
	tween.interpolate_property(inst,"position",pos+(Vector2.LEFT if sprite.flip_h else Vector2.RIGHT)*8,pos,0.2,Tween.TRANS_QUART,Tween.EASE_IN)
	tween.start()
	
	# Resize collision boundary
	shape.extents.y = 2 * slices.size() + 5.9 # Use 5.9 so we have a little clearance under gaps
	collider.position += Vector2.UP*2
	
	emit_signal("on_slice_collected",index)
