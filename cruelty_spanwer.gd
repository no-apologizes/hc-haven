extends Node3D

@export var cruelty_scene: PackedScene
@export var min_bounds: Vector2 = Vector2(-5.0, -5.0)
@export var max_bounds: Vector2 = Vector2(5.0, 5.0)
@export var spawn_height: float = 10.0

func _ready() -> void:
	spawn_cruelty()

func spawn_cruelty() -> void:
	if cruelty_scene == null:
		return
		
	var instance = cruelty_scene.instantiate()
	instance.add_to_group("cruelty")
	instance.tree_exited.connect(_on_cruelty_died)
	var random_x = randf_range(min_bounds.x, max_bounds.x)
	var random_z = randf_range(min_bounds.y, max_bounds.y)
	
	add_child(instance)
	instance.global_position = Vector3(random_x, spawn_height, random_z)


func _on_cruelty_died() -> void:
	# Skip if the spawner itself is being removed (e.g. game closing / scene change)
	if not is_inside_tree() or is_queued_for_deletion():
		return
	# Deferred so we don't add a physics body mid-physics-callback
	spawn_cruelty.call_deferred()
