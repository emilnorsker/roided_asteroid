extends RigidBody2D
class_name Satellite

@export var orbit_radius: float = 120
@export var orbit_speed: float = 1.0   # radians/sec
@export var center_node: RigidBody2D

var angle := 0.0

# Flag to avoid triggering the explosion multiple times
var _exploding := false

func _ready():
	if !center_node:
		push_error("No orbit center assigned to satellite.")
		return
	# Place the satellite at the correct starting position on its orbit
	global_position = center_node.global_position + Vector2(orbit_radius, 0).rotated(angle)

	# Calculate the tangential velocity required for a circular orbit: v = ω·r
	var radial: Vector2 = global_position - center_node.global_position
	var tangent: Vector2 = Vector2(-radial.y, radial.x).normalized()
	linear_velocity = tangent * orbit_speed * orbit_radius

	# Give the satellite a small spin so the sprite rotates nicely
	angular_velocity = 1.5

	# Ensure this body is influenced by any Area2D gravity fields (e.g. from the planet)
	gravity_scale = 1.0

	# Ensure each satellite has its own ShaderMaterial instance so uniforms aren’t shared
	var sprite: Sprite2D = $Sprite2D
	if sprite.material:
		sprite.material = sprite.material.duplicate()
		sprite.material.set_shader_parameter("progress", 0.0)


func _set_new_scale(new_scale: int) -> void:
	orbit_radius = 120.0 * new_scale

# Tween-based explosion: animate shader `progress` to 1 then free
func _explode():
	if _exploding:
		return
	_exploding = true

	# Disable collision to avoid further interactions during explosion
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	var sprite: Sprite2D = $Sprite2D
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat:
		# Ensure progress starts at current value (defaults to 0)
		var tween = create_tween()
		# Animate shader dissolve
		tween.tween_property(mat, "shader_parameter/progress", 1.0, 0.6)
		# Simultaneously scale up the sprite for a burst effect
		tween.tween_property(sprite, "scale", sprite.scale * 8.0, 0.6)
		tween.connect("finished", Callable(self, "queue_free"))
	else:
		queue_free()

# Called through the RigidBody2D signal configured in the scene
func _on_body_entered(body):
	if body.name.begins_with("Planet") or body.name == "Player":
		_explode()


func destroy():
	# Apply a blast impulse opposite to the player, if we can find them
	var player := get_tree().get_root().get_node_or_null("SolarSystem/Player")
	if player:
		var dir: Vector2 = (global_position - player.global_position).normalized()
		var impulse: Vector2 = dir * 800_000.0 + player.linear_velocity * mass
		apply_impulse(dir, impulse)
	_explode()
