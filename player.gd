extends RigidBody2D

# --- Designer knobs ---------------------------------------------------------
@export var show_debug_path: bool = true
@export var points = 0

# Preview
const BOOST_IMPULSE: float = 700.0
const GRAV_SCALE: float = 2.0	# global tuning knob
const GRAVITY_EXPONENT: float = 1.2  # 1 = slow fall-off, 2 = inverse-square

const PRED_TIME: float = 1.0
const PRED_STEPS: int = 10

var ui: Node  # this will be set externally

# Reference to Sun's gravity area for prediction
@onready var sun_area: Area2D = get_node("../Sun/InfluenceCircle")

# Cached gravitational parameter μ = g * d^2 (updated in _ready)
var mu: float = 0.0

var planets = []

# --- Runtime state ----------------------------------------------------------
# No custom gravity list needed – Area2D on the Sun handles it.

## Continuous thrust handled each physics tick --------------------------------
## Keys held down apply constant acceleration, giving smooth steering.

# Optional: give the ship an initial drift
func _ready():
	if sun_area:
		mu = sun_area.gravity * pow(sun_area.gravity_point_unit_distance, 2)
	# Enable collision callbacks and print when we hit something.
	contact_monitor = true
	max_contacts_reported = 10  # how many simultaneous contacts to track
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	print("Hit: ", body.name)
	if body.is_in_group("die_on_collision"):
		print("Died")
		_die()
	elif body.is_in_group("points_on_collision"):
		print("Points")
		points += 100
		$"../GameUI".updatePoints(points)

func _physics_process(dt: float) -> void:
	var thrust := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	if thrust != Vector2.ZERO:
		linear_velocity += thrust.normalized() * BOOST_IMPULSE * dt

	# Clamp speed so the ship remains controllable
	linear_velocity = linear_velocity.clamp(Vector2(-1500, -1500), Vector2(1500, 1500))
	if show_debug_path:
		queue_redraw()

func _die():
	# Explosion effect
	#var explosion_scene = preload("res://scenes/Explosion.tscn")
	#var explosion = explosion_scene.instantiate()
	#explosion.global_position = global_position
	#get_tree().current_scene.add_child(explosion)

	# Show death label
	$"../GameUI".diedLabel(points, true)
	#get_tree().paused = true  # freeze game

	# Disable player (or remove)
	queue_free()


func _draw():
	if !show_debug_path:
		return
	if mu == 0:
		return

	# Predict future position under current velocity and gravity forces.
	var pos: Vector2 = global_position
	var vel: Vector2 = linear_velocity
	var dt: float = PRED_TIME / PRED_STEPS
	var path: PackedVector2Array = []

	# Snapshot planet states (positions & velocities)
	var p_pos: Array = []
	var p_vel: Array = []
	for planet in planets:
		p_pos.append(planet.global_position)
		p_vel.append(planet.linear_velocity)

	for _i in PRED_STEPS:
		# --- Update planets under Sun gravity ---
		for idx in p_pos.size():
			var pp: Vector2 = p_pos[idx]
			var acc_p: Vector2 = -mu * pp / pow(max(1.0, pp.length_squared()), 1.5)
			p_vel[idx] += acc_p * dt
			p_pos[idx] += p_vel[idx] * dt

		# --- Acceleration on player ---
		var acc: Vector2 = -mu * pos / pow(max(1.0, pos.length_squared()), 1.5)
		for idx in p_pos.size():
			var area: Area2D = planets[idx].get_node_or_null("Area2D")
			if area:
				var mu_p: float = area.gravity * pow(area.gravity_point_unit_distance, 2)
				var r_vec: Vector2 = pos - p_pos[idx]
				acc += -mu_p * r_vec / pow(max(1.0, r_vec.length_squared()), 1.5)
		vel += acc * dt
		pos += vel * dt
		path.append(to_local(pos))

	# Draw dots representing the predicted trajectory.
	for point in path:
		draw_circle(point, 2.0, Color.YELLOW)
	
