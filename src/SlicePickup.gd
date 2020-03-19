extends Area2D
tool

export(int, "Patty", "Tomato", "Lettuce", "Onion", "Cheese") var slice_type : int setget set_slice_type

onready var sprite := $Sprite

func set_slice_type(val:int) -> void:
	slice_type = val if val > 0 else 0
	$Sprite.region_rect.position.y = slice_type * 16


func _on_SlicePickup_body_entered(body:PhysicsBody2D) -> void:
	
	if not sprite.visible: return
	
	if body and body.is_in_group("Player"):
		body.add_slice(slice_type)
		sprite.visible = false
