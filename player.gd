extends CharacterBody2D

# --- Designer knobs ---------------------------------------------------------
@export var show_debug_path: bool = true

# Preview
const BOOST_IMPULSE: float = 50.0
const GRAV_SCALE: float = 2.0	# global tuning knob

const PRED_TIME: float = 3.0
const PRED_STEPS: int = 30

# --- Runtime state ----------------------------------------------------------
var planets: Array = []		# injected by solar_system.gd
var lin_vel: Vector2 = Vector2.ZERO


func _unhandled_input(ev):
	if ev.is_action_pressed("space") and lin_vel.length() > 0.0:
		lin_vel += lin_vel.normalized() * BOOST_IMPULSE

func _physics_process(dt: float) -> void:
	lin_vel += _gravity_accel_at(global_position) * dt
	global_position += lin_vel * dt

	if show_debug_path:
		queue_redraw()

# ------------------------------------------------------------------
func _gravity_accel_at(pos: Vector2) -> Vector2:
	var g: Vector2 = Vector2.ZERO
	for p in planets:
		var to_p: Vector2 = p.global_position - pos
		var dist_sq: float = max(1.0, to_p.length_squared())
		g += to_p.normalized() * (p.gravity / dist_sq) * GRAV_SCALE
	return g

# ------------------------------------------------------------------
func _draw():
	if !show_debug_path:
		return
	var sim_pos: Vector2 = global_position
	var sim_vel: Vector2 = lin_vel
	var dt: float = PRED_TIME / PRED_STEPS

	var dot_r: float = 2.0
	for i in range(PRED_STEPS):
		sim_vel += _gravity_accel_at(sim_pos) * dt
		sim_pos += sim_vel * dt
		draw_circle(to_local(sim_pos), dot_r, Color.YELLOW)
