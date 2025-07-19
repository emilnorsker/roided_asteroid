extends RigidBody2D


func set_new_scale(new_scale: int) -> void:
	$Sprite2D.scale = Vector2(new_scale, new_scale)
	$CollisionShape2D.shape.radius = 58 * new_scale
	var grav = $Area2D
	grav.gravity_point_unit_distance = 58.0 * new_scale
	grav.gravity = 998.0 * new_scale
	
