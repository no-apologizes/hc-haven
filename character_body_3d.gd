extends CharacterBody3D

@export var max_pull_distance: float = 7.0
@export var launch_power: float = 8.0
@export var friction: float = 6.0
@export var min_pull_threshold: float = 0.3

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var aim_pivot: Node3D = $AimPivot
@onready var mesh = $Node3D
@onready var move_trail: GPUParticles3D = $MoveTrail

@export var ball_radius: float = 1.55

var is_dragging: bool = false
var bounceintensity: float = 1.2

func _ready() -> void:
	aim_pivot.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Only allow dragging when the character is nearly stopped
			if velocity.length() >= 0:
				var click_pos = get_mouse_ground_position()
				# Start drag if clicking near the character
				if click_pos != Vector3.ZERO and click_pos.distance_to(global_position) < 1.5:
					is_dragging = true
					aim_pivot.visible = true
		else:
			if is_dragging:
				launch()

func _process(_delta: float) -> void:
	if is_dragging:
		update_aim_arrow()

func _physics_process(delta: float) -> void:
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Apply pool-table friction to slow down smoothly
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# Save velocity before moving so we know the incoming speed
	var pre_move_velocity = velocity

	move_and_slide()

	# Bounce off wall after move_and_slide() updates collision states
	if is_on_wall():
		var normal = get_wall_normal()
		# Reflect the incoming velocity off the wall normal (optional: multiply by 0.9 for energy loss)
		var bounced = pre_move_velocity.bounce(-normal)
		velocity.x = bounced.x * bounceintensity
		velocity.z = bounced.z * bounceintensity
	
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	move_trail.emitting = horizontal_velocity.length() > 0.5
	var distance = horizontal_velocity.length() * delta
	
	if distance > 0:
		var angle_delta = distance / ball_radius
		
		var move_direction = horizontal_velocity.normalized()
		var rotation_axis = Vector3.UP.cross(move_direction)
		
		mesh.rotate(rotation_axis.normalized(), angle_delta)

func get_mouse_ground_position() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(mouse_pos)
	
	# Create an invisible horizontal mathematical plane at the character's Y height
	var ground_plane := Plane(Vector3.UP, global_position.y)
	var intersection = ground_plane.intersects_ray(ray_origin, ray_dir)
	
	return intersection if intersection != null else Vector3.ZERO

func update_aim_arrow() -> void:
	var mouse_world_pos: Vector3 = get_mouse_ground_position()
	if mouse_world_pos == Vector3.ZERO:
		return
		
	var pull_vector: Vector3 = global_position - mouse_world_pos
	pull_vector.y = 0.0
	var clamped_vector: Vector3 = pull_vector.limit_length(max_pull_distance)
	
	if clamped_vector.length() > 0.05:
		# Rotate AimPivot to point in the launch direction
		aim_pivot.look_at(global_position + clamped_vector, Vector3.UP)
		# Stretch the arrow's Z scale based on pull strength
		aim_pivot.scale.z = clamped_vector.length()

func launch() -> void:
	is_dragging = false
	aim_pivot.visible = false
	
	var mouse_world_pos: Vector3 = get_mouse_ground_position()
	if mouse_world_pos == Vector3.ZERO:
		return
		
	var pull_vector: Vector3 = global_position - mouse_world_pos
	pull_vector.y = 0.0
	var clamped_vector: Vector3 = pull_vector.limit_length(max_pull_distance)
	
	if clamped_vector.length() >= min_pull_threshold:
		velocity = clamped_vector * launch_power
