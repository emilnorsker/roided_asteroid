extends Node2D

@export var orbit_radius: float = 300.0
@export var orbit_speed: float = 1.0         # radians/sec
@export var planet_radius: float = 32.0
@export var soi_radius: float = 200.0
@export var orbit_center: Node2D           # The Sun (or other body)
@export var gravity: float = 1.0
@export var gravity_prio: int = 1

var angle := 0.0

func _ready():
	var base_texture_radius = 64.0  # Based on a 64x64 texture
	var scale_factor = planet_radius / base_texture_radius
	$Sprite2D.scale = Vector2.ONE * scale_factor

	# Set SOI size
	var shape = $Area2D.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		shape.radius = soi_radius


func _process(delta):
	angle += orbit_speed * delta

	if orbit_center:
		var center = orbit_center.global_position
		global_position = center + Vector2(orbit_radius, 0).rotated(angle)

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		body.gravity_source = self  # Set planet as gravity source
