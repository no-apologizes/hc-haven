extends Node3D

@export var cruelty_scene: PackedScene
@export var min_bounds: Vector2 = Vector2(-5.0, -5.0)
@export var max_bounds: Vector2 = Vector2(5.0, 5.0)
@export var spawn_height: float = 1.5

func _ready() -> void:
	spawn_cruelty()

func spawn_cruelty() -> void:
	if cruelty_scene == null:
		return
		
	var instance = cruelty_scene.instantiate()
	var random_x = randf_range(min_bounds.x, max_bounds.x)
	var random_z = randf_range(min_bounds.y, max_bounds.y)
	
	add_child(instance)
	instance.global_position = Vector3(random_x, spawn_height, random_z)
