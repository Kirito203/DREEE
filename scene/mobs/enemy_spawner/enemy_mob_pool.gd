extends Node

@export var mob_scene: PackedScene = preload("res://scene/mobs/eye_ball/eye_ball_v2.tscn")

@export var pool_size: int = 20
var pool: Array[CharacterBody2D] = []
var initialized: bool = false

func _ready() -> void:
	_create_pool_deferred()

func _create_pool_deferred() -> void:
	if initialized:
		return
	var batch_size: int = 10
	var created: int = 0
	while created < pool_size:
		var to_create: int = min(batch_size, pool_size - created)
		for i in range(to_create):
			var mob := _instantiate_mob()
			_deactivate_mob(mob)
			pool.append(mob)
		created += to_create
		await get_tree().process_frame
	initialized = true

func _instantiate_mob() -> CharacterBody2D:
	return mob_scene.instantiate() as CharacterBody2D

# Выдать моба из пула (без добавления в дерево)
func get_mob() -> CharacterBody2D:
	var mob: CharacterBody2D
	if pool.is_empty():
		mob = _instantiate_mob()
	else:
		mob = pool.pop_back()
	_activate_mob(mob)
	return mob

# Вернуть моба обратно в пул (спавнер или сам моб вызывает)
func return_pool(mob: CharacterBody2D) -> void:
	_deactivate_mob(mob)
	pool.append(mob)

# Удобный метод: сразу добавить моба в parent и выставить позицию
func get_and_add_mob(parent: Node, world_pos: Vector2) -> CharacterBody2D:
	var mob := get_mob()
	if mob == null or parent == null:
		return null
	parent.add_child(mob)
	mob.global_position = world_pos
	return mob

func _activate_mob(mob: CharacterBody2D) -> void:
	mob.visible = true
	mob.set_process(true)
	mob.set_physics_process(true)

func _deactivate_mob(mob: CharacterBody2D) -> void:
	mob.set_process(false)
	mob.set_physics_process(false)
	mob.visible = false
	mob.global_position = Vector2.ZERO
