extends Node2D # узел менеджера маркеров арен

@export var arena_chunks: Array[PackedScene] = [] # список сцен аренных чанков, например Chunk_Template_BA_001.tscn
@export var markers_count := 1 # сколько арен создавать
@export var min_distance := 1600.0 # минимальная дистанция от игрока до арены
@export var max_distance := 1800.0 # максимальная дистанция от игрока до арены
@export var chunk_size := Vector2i(1600, 1600) # размер чанка для выравнивания по сетке
@export var debug_log := false # включить логи для отладки местоположений арен  # ИЗМЕНИЛ добавил экспорт

var reserved_chunks: Array[Vector2i] = [] # список координат чанков, зарезервированных под арены
var player: Node2D = null # ссылка на игрока
var reservation_ready := false # флаг готовности списка reserved_chunks

func _ready() -> void: # указываем тип возврата для читаемости
	add_to_group("BossMarkersManager") # добавляем узел в группу, чтобы другие скрипты могли нас найти
	player = get_tree().get_first_node_in_group("Player") as Node2D # ищем игрока по группе и приводим к Node2D
	if player == null: # если игрок не найден
		print("Игрок не найден") # выводим предупреждение в лог
		return # прекращаем выполнение, чтобы не генерировать арены без игрока
	randomize() # инициализируем генератор случайных чисел
	_spawn_markers_and_arenas() # создаем арены на снэпнутых к сетке позициях
	reservation_ready = true # помечаем, что список reserved_chunks сформирован

func _spawn_markers_and_arenas() -> void: # указываем тип возврата
	if arena_chunks.is_empty(): # если список сцен арен пуст  # ИЗМЕНИЛ ранняя проверка
		print("Нет арен для генерации") # выводим предупреждение
		return # выходим, чтобы не падать на пустом массиве

	var tries := 0 # счётчик попыток размещения  # ИЗМЕНИЛ добавил контроль
	var max_tries := markers_count * 8 # лимит попыток, чтобы не зациклиться  # ИЗМЕНИЛ добавил лимит

	while reserved_chunks.size() < markers_count and tries < max_tries: # крутим до нужного числа  # ИЗМЕНИЛ цикл вместо for
		tries += 1 # наращиваем попытку

		var angle: float = randf() * TAU # случайный угол вокруг игрока
		var dist: float = randf_range(min_distance, max_distance) # случайная дистанция в заданном диапазоне
		var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist # мировая точка для арены

		var coord: Vector2i = Vector2i( # координата чанка для выравнивания по сетке
			int(floor(pos.x / float(chunk_size.x))), # индекс чанка по X  # ИЗМЕНИЛ явный float
			int(floor(pos.y / float(chunk_size.y)))  # индекс чанка по Y  # ИЗМЕНИЛ явный float
		)

		if reserved_chunks.has(coord): # если такой чанк уже зарезервирован
			continue # пропускаем этот вариант и идем дальше

		reserved_chunks.append(coord) # добавляем координату в список зарезервированных

		var random_index: int = randi() % arena_chunks.size() # выбираем случайный индекс арены
		var arena_scene: PackedScene = arena_chunks[random_index] # берем сцену арены по индексу
		var arena_instance: Node2D = arena_scene.instantiate() as Node2D # создаем инстанс и приводим к Node2D
		if arena_instance == null: # проверяем инстанс  # ИЗМЕНИЛ защиту
			if debug_log: print("instantiate arena failed at ", coord) # лог ошибки
			continue # пробуем другую попытку

		add_child(arena_instance) # добавляем арену в сцену как ребенка менеджера
		arena_instance.global_position = Vector2(coord.x * chunk_size.x, coord.y * chunk_size.y) # ставим арену по координатам сетки
		arena_instance.add_to_group("BossArenaChunks") # добавляем арену в группу для удобства поиска

		var world_pos: Vector2 = arena_instance.global_position # сохраняем мировую позицию арены с явным типом
		var distance: int = int(player.global_position.distance_to(world_pos)) # рассчитываем дистанцию от игрока и задаем тип int
		if debug_log: print("Создана арена №", reserved_chunks.size(), " в чанке ", coord, " позиция ", world_pos, " дистанция ", distance) # печатаем подсказку куда бежать  # изменил лог по флагу
