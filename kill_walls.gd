extends Area3D

const EXPLOSION_SOUND := preload("res://assets/Explosion.mp3")

@export var explosion_color: Color = Color(1.0, 0.45, 0.1)
@export var explosion_size: float = 0.6


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("cruelty") and not body.is_queued_for_deletion():
		explode(body)


func explode(body: Node3D) -> void:
	var pos := body.global_position
	var root := get_tree().current_scene

	# Burst of glowing particles
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 60
	particles.lifetime = 0.8
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 6.0
	particles.initial_velocity_max = 14.0
	particles.gravity = Vector3(0, -9.8, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.2
	var mesh := SphereMesh.new()
	mesh.radius = explosion_size * 0.5
	mesh.height = explosion_size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = explosion_color
	mat.emission_enabled = true
	mat.emission = explosion_color
	mat.emission_energy_multiplier = 3.0
	mesh.material = mat
	particles.mesh = mesh
	root.add_child(particles)
	particles.global_position = pos
	particles.emitting = true

	# Boom sound
	var sound := AudioStreamPlayer3D.new()
	sound.stream = EXPLOSION_SOUND
	root.add_child(sound)
	sound.global_position = pos
	sound.play()

	# Clean up the effects afterwards
	get_tree().create_timer(3.0).timeout.connect(func():
		particles.queue_free()
		sound.queue_free())

	body.queue_free()
