extends Node2D

@export var orbit_radius: float = 40.0
@export var orbit_speed: float = 1.0   # radians/sec
var angle := 0.0
var center_node: Node2D

func _ready():
	if !center_node:
		push_error("No orbit center assigned to satellite.")
		return
	global_position = center_node.global_position + Vector2(orbit_radius, 0).rotated(angle)

func _process(delta):
	if !center_node:
		return
	angle += orbit_speed * delta
	global_position = center_node.global_position + Vector2(orbit_radius, 0).rotated(angle)
	rotation += 1.5 * delta  # Spin the satellite itself

func _on_Area2D_body_entered(body):
	if body.name.begins_with("Planet") or body.name == "Player":
		queue_free()  # Satellite explodes (simple version)
