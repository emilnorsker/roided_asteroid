extends RigidBody2D

# -----------------------------------------------------------------------------
# Minimal arcade-orbit body.
# The planet moves under the gravitational pull of a fixed centre at (0,0)
# (the SolarSystem node’s origin). SolarSystem sets the initial `vel`.
# No exported vars – all numbers live in code for leaner runtime.
# -----------------------------------------------------------------------------

# Removed manual velocity integration – the built-in physics engine now
# handles motion entirely. Planets are `RigidBody2D`s that respond to
# the Sun’s point gravity set in `solar_system.gd`.

# Mass parameter used by the player’s weak-gravity pull.  
# Keep as simple scalar; doesn’t need to be physically correct.
var gravity: float = 8_000.0

# Whether the player can snap into spring orbit around this body
var allow_capture: bool = true

# Sun gravitational parameter (match solar_system)
const SUN_MU: float = 8.0e4

func _ready() -> void:
	custom_integrator = true
	linear_damp = 0.0
	angular_damp = 0.0
	gravity_scale = 0.0   # ignore Area2D gravity

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var r: Vector2 = global_position
	var dist_sq: float = max(1.0, r.length_squared())
	var acc: Vector2 = -SUN_MU * r / pow(dist_sq, 1.5)
	state.linear_velocity += acc * state.step
