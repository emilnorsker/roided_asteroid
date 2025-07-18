extends Node2D

# -----------------------------------------------------------------------------
# Minimal arcade-orbit body.
# The planet moves under the gravitational pull of a fixed centre at (0,0)
# (the SolarSystem node’s origin). SolarSystem sets the initial `vel`.
# No exported vars – all numbers live in code for leaner runtime.
# -----------------------------------------------------------------------------

const MU_SUN: float = 5.0e4   # Gravitational parameter of the sun (tune once)

# Radius that counts as this planet’s sphere-of-influence.  
# Used by the player script to decide capture.
var soi_radius: float = 80000.0

# Mass parameter used by the player’s weak-gravity pull.  
# Keep as simple scalar; doesn’t need to be physically correct.
var gravity: float = 800_000.0

# Whether the player can snap into spring orbit around this body
var allow_capture: bool = true

# Current velocity (set by the spawner)
var vel: Vector2 = Vector2.ZERO

func _physics_process(dt: float) -> void:
	# Two-body acceleration toward origin
	var r: Vector2 = global_position
	var dist_sq: float = max(1.0, r.length_squared())
	var acc: Vector2 = -MU_SUN * r / pow(dist_sq, 1.5)
	# clamp max acceleration to 1000
	acc = acc.clamp(Vector2(-1000.0, -1000.0), Vector2(1000.0, 1000.0))

	vel += acc * dt
	global_position += vel * dt
