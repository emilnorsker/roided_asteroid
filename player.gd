extends RigidBody2D

# --- Designer knobs ---------------------------------------------------------
@export var show_debug_path: bool = true

# Preview
const BOOST_IMPULSE: float = 700.0
const GRAV_SCALE: float = 2.0	# global tuning knob
const GRAVITY_EXPONENT: float = 1.2  # 1 = slow fall-off, 2 = inverse-square

const PRED_TIME: float = 3.0
const PRED_STEPS: int = 60

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
	print("Player collided with %s" % body.name)

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

# Removed custom gravity calculation – Sun's Area2D now drives gravity.

# ------------------------------------------------------------------
func _draw():
	if !show_debug_path:
		return

	if mu == 0:
		return
	var pos: Vector2 = global_position
	var vel: Vector2 = linear_velocity
	var dt: float = PRED_TIME / PRED_STEPS
	var dot_r: float = 2.0
	# snapshot planet states
	var p_pos: Array = []
	var p_vel: Array = []
	for planet in planets:
		p_pos.append(planet.global_position)
		p_vel.append(planet.linear_velocity)

	for _step in PRED_STEPS:
		draw_circle(to_local(pos), dot_r, Color.YELLOW)
