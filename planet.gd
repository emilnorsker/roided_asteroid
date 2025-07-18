extends Node2D

@export var orbit_radius: float = 300.0
@export var orbit_speed: float = 1.0         # radians/sec
@export var planet_radius: float = 32.0
@export var soi_radius: float = 200.0
@export var orbit_center: Node2D           # The Sun (or other body)
@export var gravity: float = 1.0
@export var gravity_prio: int = 1
@export var is_destructible: bool = false

var angle := 0.0

func _ready():
	var tex = $Sprite2D.texture
	if tex:
		var texture_size = tex.get_size().x  # assumes square texture
		var scale_factor = planet_radius / (texture_size / 2.0)  # match radius to texture's *visual* radius
		$Sprite2D.scale = Vector2.ONE * scale_factor
	else:
		push_warning("No texture set on Sprite2D!")

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
