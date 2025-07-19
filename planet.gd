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

# Whether the player can snap into spring orbit around this body

# Sun gravitational parameter (match solar_system)
