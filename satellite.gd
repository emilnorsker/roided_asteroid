extends RigidBody2D
class_name Satellite

@export var orbit_radius: float = 120
@export var orbit_speed: float = 1.0   # radians/sec
@export var center_node: RigidBody2D

var angle := 0.0

func _ready():
	if !center_node:
		push_error("No orbit center assigned to satellite.")
		return
	global_position = center_node.global_position + Vector2(orbit_radius, 0).rotated(angle)
	# Ensure the Area2D hitbox notifies this satellite when it touches other bodies
	if has_node("Area2D"):
		$Area2D.body_entered.connect(_on_Area2D_body_entered)

func _process(delta):
	if !center_node:
		return
	angle += orbit_speed * delta
	global_position = center_node.global_position + Vector2(orbit_radius, 0).rotated(angle)
	rotation += 1.5 * delta  # Spin the satellite itself

func _on_Area2D_body_entered(body):
	if body.name.begins_with("Planet") or body.name == "Player":
		queue_free()  # Satellite explodes (simple version)

func _set_new_scale(new_scale: int) -> void:
	orbit_radius = 120.0 * new_scale
	
