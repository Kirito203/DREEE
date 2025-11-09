extends Node2D # корневой узел генератора обычных чанков

@export var chunk_variants: Array[PackedScene] = [] # список шаблонов обычных чанков
@export var chunk_size := Vector2i(1600, 1600) # размер одного чанка
@export var debug_log := false # включить подробные логи для отладки  # ИЗМЕНИЛ добавил флаг ранее

@export var keep_radius := Vector2i(2, 2) # радиус окна загрузки по чанкам
@export var max_spawns_per_tick := 1 # максимум спавнов за кадр
@export var unload_enabled := true # включить выгрузку дальних чанков

@onready var player: Node2D = get_tree().get_first_node_in_group("Player") # ссылка на игрока с типом  # ИЗМЕНИЛ добавил тип

var chunk_queue: Array[Vector2i] = [] # очередь координат чанков на генерацию
var is_spawning_chunk: bool = false # флаг, идёт ли генерация  # ИЗМЕНИЛ добавил тип
var loaded_chunks: Dictionary = {} # словарь coord -> инстанс  # ИЗМЕНИЛ добавил тип Dictionary

var boss_markers_manager: Node = null # кэш ссылки на менеджер арен

var _reserved_cache_ready: bool = false # кэш готовности сета брони  # ИЗМЕНИЛ добавил тип
var _reserved_set: Dictionary = {} # set зарезервированных чанков  # ИЗМЕНИЛ добавил тип Dictionary

func _ready() -> void:
	randomize() # инициализируем генератор случайных чисел

func _process(_delta: float) -> void:
	if player == null: # если игрок не найден
		return # выходим до следующего кадра
		
	if boss_markers_manager == null: # если менеджер ещё не закэширован
		boss_markers_manager = get_tree().get_first_node_in_group("BossMarkersManager") # ищем по группе
		
	if not _reserved_cache_ready and boss_markers_manager != null: # если кэш ещё не собран и менеджер есть
		var ready_var = boss_markers_manager.get("reservation_ready") # читаем флаг из менеджера
		if typeof(ready_var) == TYPE_BOOL and ready_var: # если готов
			_reserved_set.clear() # очищаем сет
			var arr = boss_markers_manager.get("reserved_chunks") # читаем массив координат
			if arr is Array: # проверяем тип
				for v in (arr as Array): # перебираем элементы
					if v is Vector2i: # только Vector2i
						_reserved_set[v] = true # кладём в множество
			_reserved_cache_ready = true # помечаем кэш собран
			
	var player_chunk_pos: Vector2i = _world_to_chunk(player.global_position) # вычисляем чанк игрока  # ИЗМЕНИЛ задал тип
	
	_queue_window_around(player_chunk_pos) # ставим недостающие чанки в очередь
	
	if unload_enabled: # если включена выгрузка
		_unload_far_chunks(player_chunk_pos) # выгружаем дальние чанки
		
	var spawns_left: int = max(1, max_spawns_per_tick) # лимит спавнов как int  # ИЗМЕНИЛ явный тип int
	while spawns_left > 0 and chunk_queue.size() > 0 and not is_spawning_chunk: # пока можно спавнить
		_spawn_chunk_from_queue() # создаём один чанк
		spawns_left -= 1 # уменьшаем лимит

func _spawn_chunk_from_queue() -> void:
	is_spawning_chunk = true # включаем флаг генерации
	
	var coord: Vector2i = chunk_queue.pop_front() # берём координату из очереди
	
	if _reserved_cache_ready and _reserved_set.has(coord): # если координата забронирована ареной
		if debug_log: print("spawn skip reserved ", coord) # отладочный лог
		is_spawning_chunk = false # снимаем флаг
		return # выходим без генерации
		
	if chunk_variants.is_empty(): # если нет обычных шаблонов
		if debug_log: print("no chunk_variants, skip spawn") # отладочный лог
		is_spawning_chunk = false # снимаем флаг
		return # выходим
		
	var random_index: int = randi() % chunk_variants.size() # выбираем случайный индекс шаблона как int  # ИЗМЕНИЛ явный тип int
	var chunk_scene: PackedScene = chunk_variants[random_index] # берём сцену по индексу
	var chunk_instance: Node2D = chunk_scene.instantiate() as Node2D # создаём инстанс и приводим к Node2D
	if chunk_instance == null: # проверяем инстанс
		if debug_log: print("instantiate failed at ", coord) # лог ошибки
		is_spawning_chunk = false # снимаем флаг
		return # выходим
		
	add_child(chunk_instance) # добавляем чанк в сцену
	chunk_instance.position = Vector2(coord.x * chunk_size.x, coord.y * chunk_size.y) # ставим по сетке как Vector2  # ИЗМЕНИЛ явное Vector2
	loaded_chunks[coord] = chunk_instance # запоминаем созданный чанк
	
	if debug_log: print("spawned chunk at ", coord, " world_pos ", chunk_instance.global_position) # отладочный лог
	
	await get_tree().process_frame # ждём один кадр
	is_spawning_chunk = false # снимаем флаг генерации

func _queue_window_around(center_coord: Vector2i) -> void: # утилита постановки окна в очередь
	for x in range(-keep_radius.x, keep_radius.x + 1): # проходим окно по X
		for y in range(-keep_radius.y, keep_radius.y + 1): # проходим окно по Y
			var coord: Vector2i = center_coord + Vector2i(x, y) # координата проверяемого чанка  # ИЗМЕНИЛ явный тип Vector2i
			if _reserved_cache_ready and _reserved_set.has(coord): # если чанк зарезервирован
				if debug_log: print("queue skip reserved ", coord) # отладочный лог
				continue # не ставим в очередь
			if not loaded_chunks.has(coord) and not chunk_queue.has(coord): # если нет и не в очереди
				chunk_queue.append(coord) # ставим в очередь

func _unload_far_chunks(center_coord: Vector2i) -> void: # выгрузка дальних чанков
	var to_free: Array[Vector2i] = [] # список на удаление
	for coord in loaded_chunks.keys(): # обходим все загруженные
		var dx: int = abs(coord.x - center_coord.x) # расстояние по X как int  # ИЗМЕНИЛ явный тип int
		var dy: int = abs(coord.y - center_coord.y) # расстояние по Y как int  # ИЗМЕНИЛ явный тип int
		if dx > keep_radius.x or dy > keep_radius.y: # если за окном
			to_free.append(coord) # помечаем к удалению
	for coord in to_free: # удаляем помеченные
		var node: Node = loaded_chunks.get(coord, null) as Node # берём узел с типом  # ИЗМЕНИЛ добавил тип
		if node != null and is_instance_valid(node): # проверяем валидность
			node.queue_free() # удаляем из сцены
		loaded_chunks.erase(coord) # убираем из словаря
		if debug_log: print("unloaded chunk ", coord) # отладочный лог

func _world_to_chunk(world_pos: Vector2) -> Vector2i: # перевод мира в индекс чанка
	return Vector2i( # возвращаем индекс
		int(floor(world_pos.x / float(chunk_size.x))), # индекс по X
		int(floor(world_pos.y / float(chunk_size.y)))  # индекс по Y
	)
