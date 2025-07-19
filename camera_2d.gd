extends Camera2D

# Dynamically adjusts camera zoom based on distance to the Sun.
# Farther from the Sun → zooms out (shows larger area).

@export var sun_path: NodePath = NodePath("../../Sun")

# Distance thresholds (in pixels).
@export var close_dist: float = 200.0    # within this distance use max_zoom
@export var far_dist: float = 1500.0     # beyond this distance use min_zoom

# Zoom limits (Vector2 uses same value on x & y)
@export var max_zoom: float = 0.6        # when close to the Sun (default scene value)
@export var min_zoom: float = 0.4        # when far from the Sun (zoomed-out)

@export var margin: float = 164.0      # extra padding to keep Sun off the very edge
@export var intro_zoom_factor: float = 1.5   # How much tighter than max_zoom we start.
@export var intro_zoom_time  : float = 3.0   # Seconds it takes to ease-out.

# Internal
var _intro_done := false

@onready var sun: Node2D = get_node_or_null(sun_path)

func _ready() -> void:
	if sun == null:                # No Sun found – fall back to regular logic.
		_intro_done = true
		push_error("no sun")
		return

	# 1. Force initial zoom-in
	var start_zoom :=  intro_zoom_factor / min_zoom   # 2.5× closer (= smaller zoom value)
	zoom = Vector2(start_zoom, start_zoom)

	# 2. Work out where we *should* be right now and tween toward it.
	var target_zoom := _compute_target_zoom()
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "zoom", Vector2(target_zoom, target_zoom), intro_zoom_time)
	tw.finished.connect(func(): _intro_done = true)

func _physics_process(_dt: float) -> void:
	if sun == null:
		return

	# While the intro tween is running we ignore dynamic zoom.
	if not _intro_done:
		return

	# --- original body unchanged ------------------------------------------
	var target_zoom: float = _compute_target_zoom()
	zoom = Vector2(target_zoom, target_zoom)
	# -----------------------------------------------------------------------

func _compute_target_zoom() -> float:
	var dist: float = global_position.distance_to(sun.global_position)
	var t: float = clamp((dist - close_dist) / (far_dist - close_dist), 0.0, 1.0)
	var target_zoom: float = lerp(max_zoom, min_zoom, t)

	# Ensure the Sun fits within the visible area ---------------------------
	var view_size: Vector2 = get_viewport_rect().size
	var cam_offset: Vector2 = sun.global_position - global_position
	var needed_half_w: float = abs(cam_offset.x) + margin
	var needed_half_h: float = abs(cam_offset.y) + margin

	var max_zoom_allow_x: float = view_size.x / (needed_half_w * 2.0)
	var max_zoom_allow_y: float = view_size.y / (needed_half_h * 2.0)
	var zoom_to_fit: float = min(max_zoom_allow_x, max_zoom_allow_y)

	target_zoom = min(target_zoom, zoom_to_fit)
	return clamp(target_zoom, 0.1, max_zoom)
