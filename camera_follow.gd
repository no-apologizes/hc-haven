extends Camera3D

@export var target: Node3D
@export var target_offset: Vector3 = Vector3.ZERO

@export_group("Tracking Settings")
## Lower values make the camera turn slower and feel heavier.
@export_range(0.1, 10.0) var rotation_speed: float = 1
## Maximum angle (in degrees) the camera can turn from its starting view.
@export_range(0.0, 180.0) var max_turn_degrees: float = 5
## Camera ignores target movement until it exceeds this angle.
@export_range(0.0, 45.0) var deadzone_degrees: float = 2.0

var _initial_quat: Quaternion

func _ready() -> void:
	# Save the starting orientation so we know where "center" is
	_initial_quat = global_transform.basis.get_rotation_quaternion()

func _process(delta: float) -> void:
	if not target:
		return

	var target_pos = target.global_position + target_offset
	
	if global_position.is_equal_approx(target_pos):
		return

	# 1. Find the ideal rotation to look at verity
	var look_transform = global_transform.looking_at(target_pos, Vector3.UP)
	var look_quat = look_transform.basis.get_rotation_quaternion()

	# 2. Check the deadzone (ignore tiny movements near the center)
	var angle_from_center = rad_to_deg(_initial_quat.angle_to(look_quat))
	if angle_from_center < deadzone_degrees:
		look_quat = _initial_quat
	# 3. Clamp the maximum turn angle so the arena stays framed
	elif angle_from_center > max_turn_degrees:
		var t = max_turn_degrees / angle_from_center
		look_quat = _initial_quat.slerp(look_quat, t)

	# 4. Frame-rate independent smooth interpolation
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var weight = 1.0 - exp(-rotation_speed * delta)
	global_transform.basis = Basis(current_quat.slerp(look_quat, weight))
