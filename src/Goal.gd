extends Area2D

signal on_goal_reached

func _on_Goal_body_entered(body):
	if body and body.is_in_group("Player"):
		emit_signal("on_goal_reached")
