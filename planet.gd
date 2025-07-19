extends RigidBody2D


func set_new_scale(new_scale: int) -> void:
	$Sprite2D.scale = Vector2(new_scale, new_scale)
	mass = 1000 * new_scale
	
	var shape = CircleShape2D.new()
	shape.radius = 58.0 * new_scale

	$CollisionShape2D.shape = shape
	
	var grav = $Area2D
	grav.gravity_point_unit_distance = 64.0 * new_scale
	grav.gravity = 1_998.0 * new_scale


	var grav_shape = CircleShape2D.new()
	grav_shape.radius = 58.0 * new_scale * 5.0
	
	$Area2D/CollisionShape2D.shape = grav_shape

	for child in get_children():
		var sat = child as Satellite
		if sat:
			sat._set_new_scale(new_scale)
	
