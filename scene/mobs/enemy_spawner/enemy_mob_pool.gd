extends Node

@export var mob_scene: PackedScene = preload("res://scene/mobs/eye_ball/eye_ball_v2.tscn")
@export var pool_size: int = 50
@export var warm_up_on_ready: bool = true
@export var dynamic_pool_growth: bool = true
@export var max_pool_size: int = 100

var pool: Array[CharacterBody2D] = []
var available_indices: Array[int] = []
var initialized: bool = false

func _ready() -> void:
	if warm_up_on_ready:
		call_deferred("_warm_up_pool")

func _warm_up_pool() -> void:
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
			available_indices.append(created + i)
		
		created += to_create
		await get_tree().process_frame
	
	initialized = true
	print("MobPool: Initialized with ", pool.size(), " mobs")

func _instantiate_mob() -> CharacterBody2D:
	if mob_scene == null:
		push_error("MobPool: mob_scene is not set!")
		return null
	return mob_scene.instantiate() as CharacterBody2D

# Основная функция получения моба
func get_mob() -> CharacterBody2D:
	if available_indices.is_empty():
		if dynamic_pool_growth and pool.size() < max_pool_size:
			# Динамическое расширение пула
			var new_mob = _instantiate_mob()
			if new_mob:
				pool.append(new_mob)
				_activate_mob(new_mob)
				print("MobPool: Dynamically expanded to ", pool.size(), " mobs")
				return new_mob
		else:
			print("MobPool: No available mobs and pool at maximum size")
			return null
	
	var idx = available_indices.pop_back()
	var mob = pool[idx]
	if mob:
		_activate_mob(mob)
	return mob

# Удобный метод: сразу добавить моба в parent и выставить позицию
func get_and_add_mob(parent: Node, world_pos: Vector2) -> CharacterBody2D:
	var mob := get_mob()
	if mob == null or parent == null:
		return null
	
	parent.add_child(mob)
	mob.global_position = world_pos
	
	# Вызываем активацию спавна если есть такой метод
	if mob.has_method("on_spawn_activated"):
		mob.call_deferred("on_spawn_activated")
	
	return mob

# Вернуть моба обратно в пул
func return_pool(mob: CharacterBody2D) -> void:
	if mob == null:
		return
	
	var idx = pool.find(mob)
	if idx != -1:
		_deactivate_mob(mob)
		available_indices.append(idx)
	else:
		# Если моб не из пула, но нужно вернуть - добавляем в пул
		if dynamic_pool_growth and pool.size() < max_pool_size:
			_deactivate_mob(mob)
			pool.append(mob)
			available_indices.append(pool.size() - 1)

func _activate_mob(mob: CharacterBody2D) -> void:
	if mob == null:
		return
	
	mob.visible = true
	mob.set_process(true)
	mob.set_physics_process(true)
	
	# Включаем коллизии
	for child in mob.get_children():
		if child is CollisionShape2D:
			child.disabled = false

func _deactivate_mob(mob: CharacterBody2D) -> void:
	if mob == null:
		return
	
	mob.set_process(false)
	mob.set_physics_process(false)
	mob.visible = false
	mob.global_position = Vector2(-10000, -10000) # Убираем далеко от камеры
	
	# Отключаем коллизии
	for child in mob.get_children():
		if child is CollisionShape2D:
			child.disabled = true
	
	# Удаляем из родителя, но не удаляем полностью
	if mob.get_parent():
		mob.get_parent().remove_child(mob)

# Статистика пула
func get_pool_stats() -> Dictionary:
	return {
		"total_size": pool.size(),
		"available": available_indices.size(),
		"in_use": pool.size() - available_indices.size()
	}

# Принудительная очистка пула
func clear_pool() -> void:
	for mob in pool:
		if is_instance_valid(mob):
			mob.queue_free()
	
	pool.clear()
	available_indices.clear()
	initialized = false
