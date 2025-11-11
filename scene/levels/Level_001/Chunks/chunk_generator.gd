extends Node2D

@export var chunk_variants: Array[PackedScene] = []
@export var chunk_size := Vector2i(1600, 1600)
@export var debug_log := false
@export var keep_radius := Vector2i(2, 2)
@export var max_spawns_per_tick := 2
@export var unload_enabled := true

@onready var player: Node2D = get_tree().get_first_node_in_group("Player")

var chunk_queue: Array[Vector2i] = []
var is_spawning_chunk: bool = false
var loaded_chunks: Dictionary = {}
var boss_markers_manager: Node = null
var _reserved_cache_ready: bool = false
var _reserved_set: Dictionary = {}

# Оптимизации
var _last_player_chunk: Vector2i = Vector2i.ZERO
var _update_cooldown: float = 0.0
var _update_interval: float = 0.1  # 100ms

func _ready() -> void:
	randomize()
	# Сразу спавним начальные чанки
	_force_initial_chunks()

func _force_initial_chunks() -> void:
	if player:
		var player_chunk = _world_to_chunk(player.global_position)
		_queue_window_around(player_chunk)
		# Немедленно спавним несколько чанков
		for i in range(min(3, chunk_queue.size())):
			_spawn_chunk_from_queue()

func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		return
	
	# Обновляем не каждый кадр
	_update_cooldown -= delta
	if _update_cooldown > 0:
		return
	_update_cooldown = _update_interval
	
	var player_chunk: Vector2i = _world_to_chunk(player.global_position)
	
	# Обновляем только если игрок переместился между чанками
	if player_chunk != _last_player_chunk:
		_last_player_chunk = player_chunk
		
		if boss_markers_manager == null:
			boss_markers_manager = get_tree().get_first_node_in_group("BossMarkersManager")
			
		if not _reserved_cache_ready and boss_markers_manager != null:
			var ready_var = boss_markers_manager.get("reservation_ready")
			if typeof(ready_var) == TYPE_BOOL and ready_var:
				_reserved_set.clear()
				var arr = boss_markers_manager.get("reserved_chunks")
				if arr is Array:
					for v in arr:
						if v is Vector2i:
							_reserved_set[v] = true
				_reserved_cache_ready = true
		
		_queue_window_around(player_chunk)
		
		if unload_enabled:
			_unload_far_chunks(player_chunk)
	
	# Спавним чанки из очереди
	var spawns_left: int = max_spawns_per_tick
	while spawns_left > 0 and chunk_queue.size() > 0 and not is_spawning_chunk:
		_spawn_chunk_from_queue()
		spawns_left -= 1

func _spawn_chunk_from_queue() -> void:
	is_spawning_chunk = true
	
	var coord: Vector2i = chunk_queue.pop_front()
	
	if _reserved_cache_ready and _reserved_set.has(coord):
		if debug_log: 
			print("spawn skip reserved ", coord)
		is_spawning_chunk = false
		return
		
	if chunk_variants.is_empty():
		if debug_log: 
			print("no chunk_variants, skip spawn")
		is_spawning_chunk = false
		return
		
	var random_index: int = randi() % chunk_variants.size()
	var chunk_scene: PackedScene = chunk_variants[random_index]
	var chunk_instance: Node2D = chunk_scene.instantiate() as Node2D
	
	if chunk_instance == null:
		if debug_log: 
			print("instantiate failed at ", coord)
		is_spawning_chunk = false
		return
		
	add_child(chunk_instance)
	chunk_instance.position = Vector2(coord.x * chunk_size.x, coord.y * chunk_size.y)
	loaded_chunks[coord] = chunk_instance
	
	if debug_log: 
		print("spawned chunk at ", coord, " world_pos ", chunk_instance.global_position)
	
	# Убираем await - он вызывает фризы
	call_deferred("_finish_spawn")

func _finish_spawn() -> void:
	is_spawning_chunk = false

func _queue_window_around(center_coord: Vector2i) -> void:
	for x in range(-keep_radius.x, keep_radius.x + 1):
		for y in range(-keep_radius.y, keep_radius.y + 1):
			var coord: Vector2i = center_coord + Vector2i(x, y)
			if _reserved_cache_ready and _reserved_set.has(coord):
				if debug_log: 
					print("queue skip reserved ", coord)
				continue
			if not loaded_chunks.has(coord) and not chunk_queue.has(coord):
				chunk_queue.append(coord)
				if debug_log: 
					print("queued chunk ", coord)

func _unload_far_chunks(center_coord: Vector2i) -> void:
	var to_free: Array[Vector2i] = []
	for coord in loaded_chunks.keys():
		var dx: int = abs(coord.x - center_coord.x)
		var dy: int = abs(coord.y - center_coord.y)
		if dx > keep_radius.x or dy > keep_radius.y:
			to_free.append(coord)
			
	for coord in to_free:
		var node: Node = loaded_chunks[coord]
		if is_instance_valid(node):
			node.queue_free()
		loaded_chunks.erase(coord)
		if debug_log: 
			print("unloaded chunk ", coord)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_pos.x / chunk_size.x),
		floor(world_pos.y / chunk_size.y)
	)

# Дебаг функции
func get_debug_info() -> Dictionary:
	return {
		"loaded_chunks": loaded_chunks.size(),
		"chunk_queue": chunk_queue.size(),
		"player_chunk": _last_player_chunk,
		"is_spawning": is_spawning_chunk
	}

# Принудительно обновить все чанки вокруг игрока
func force_update_around_player() -> void:
	if player:
		var player_chunk = _world_to_chunk(player.global_position)
		_last_player_chunk = Vector2i(999, 999)  # Сбрасываем кэш
		_queue_window_around(player_chunk)
