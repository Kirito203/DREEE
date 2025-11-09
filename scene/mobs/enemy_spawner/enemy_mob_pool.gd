extends Node

@export var mob_scene: PackedScene = preload("res://scene/mobs/eye_ball/eye_ball_v2.tscn")
@export var pool_size: int = 40

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
			var mob: CharacterBody2D = _instantiate_mob()
			_prepare_for_pool(mob)
			pool.append(mob)
		created += to_create
		await get_tree().process_frame
	initialized = true

func _instantiate_mob() -> CharacterBody2D:
	return mob_scene.instantiate() as CharacterBody2D

# Выдать моба из пула
func get_mob() -> CharacterBody2D:
	var mob: CharacterBody2D
	if pool.is_empty():
		mob = _instantiate_mob()
	else:
		mob = pool.pop_back()
	_activate_for_spawn(mob)
	return mob

# Вернуть моба обратно в пул
func return_pool(mob: CharacterBody2D) -> void:
	_prepare_for_pool(mob)
	pool.append(mob)

# Отложенное добавление в дерево и установка позиции
func place_mob_deferred(parent: Node, world_pos: Vector2, mob: CharacterBody2D) -> void:
	if parent == null or mob == null:
		return
	mob.global_position = world_pos
	call_deferred("_add_to_parent", parent, mob)

func _add_to_parent(parent: Node, mob: CharacterBody2D) -> void:
	if mob.get_parent() != null:
		mob.get_parent().remove_child(mob)
	parent.add_child(mob)
	# включаем логику после кадра (моб должен иметь метод on_spawn_activated)
	mob.call_deferred("on_spawn_activated")

# Внутренние состояния
func _activate_for_spawn(mob: CharacterBody2D) -> void:
	mob.visible = true
	mob.set_process(false)
	mob.set_physics_process(false)

func _prepare_for_pool(mob: CharacterBody2D) -> void:
	mob.set_process(false)
	mob.set_physics_process(false)
	mob.visible = false
	mob.global_position = Vector2.ZERO
