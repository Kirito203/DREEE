extends Node2D # узел для спавна врагов

@export var enemy_scene: PackedScene # сцена врага

var spawn_distance := 400.0 # максимум от игрока
var min_offset := 300.0 # минимум от игрока

var min_enemies_normal := 30 # старт обычной волны
var max_enemies_normal := 30000 # конец обычной волны

var first_horde_time := 60.0 # время первой толпы
var horde_interval := 120.0 # период толпы
var horde_duration := 20.0 # длительность толпы

var min_enemies_horde := 120 # старт толпы
var max_enemies_horde := 100000 # конец толпы

var base_spawn_interval := 0.4 # интервал обычнойвф
var horde_spawn_interval := 0.1 # интервал толпы
var session_duration := 5.0 * 60.0 # длительность сессии
var cap_concurrent_enemies := 500000 # лимит врагов

@export var respawn_radius := 600.0 # радиус рецикла
@export var max_recycles_per_tick := 8 # лимит рецикла/кадр

var spawn_timer := 0.0 # таймер спавна
var session_timer := 0.0 # таймер сессии

var player: Node2D = null # ссылка на игрока

var was_horde := false # флаг внутри толпы
var current_horde_start := 0.0 # время старта толпы
var horde_index := 0 # номер текущей толпы

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Node2D # ищем игрока
	randomize() # включаем рандом

func _process(delta: float) -> void:
	if session_timer >= session_duration: # если сессия кончилась
		return # выходим
	session_timer += delta # накапливаем время
	_update_horde_state() # обновляем состояние толпы
	_handle_spawning(delta) # логика спавна
	_recycle_far_enemies() # рецикл дальних

func _update_horde_state() -> void:
	var active := _is_horde_active() # текущее состояние
	if active and not was_horde: # вход в толпу
		current_horde_start = session_timer # запоминаем старт
		horde_index += 1 # увеличиваем счётчик
		was_horde = true # ставим флаг
	elif not active and was_horde: # выход из толпы
		was_horde = false # сбрасываем флаг

func _handle_spawning(_delta: float) -> void:
	spawn_timer += _delta # накапливаем таймер
	var interval := horde_spawn_interval if _is_horde_active() else base_spawn_interval # активный интервал
	if spawn_timer < interval: # если рано
		return # ждём
	spawn_timer = 0.0 # сбрасываем

	if player == null or enemy_scene == null: # проверяем ссылки
		player = get_tree().get_first_node_in_group("Player") as Node2D # пробуем найти
		return # ждём кадр

	var alive := _get_alive_enemies() # сколько живо
	if alive >= cap_concurrent_enemies: # достигли лимита
		return # стоп

	if _is_horde_active(): # если толпа
		if alive < _get_current_horde_target(): # не достигли цели
			_spawn_enemy_around_player() # спавним
	else: # обычная волна
		if alive < _get_current_normal_target(): # не достигли цели
			_spawn_enemy_around_player() # спавним

func _get_current_normal_target() -> int:
	var progress: float = clampf(session_timer / session_duration, 0.0, 1.0) # доля 0..1
	return int(lerpf(float(min_enemies_normal), float(max_enemies_normal), progress)) # линейный рост

func _get_current_horde_target() -> int:
	var session_progress: float = clampf(session_timer / session_duration, 0.0, 1.0) # прогресс сессии
	var horde_progress: float = 0.0 # прогресс окна
	if was_horde: # если внутри окна
		horde_progress = clampf((session_timer - current_horde_start) / horde_duration, 0.0, 1.0) # 0..1
	var combined: float = clampf(0.5 * session_progress + 0.5 * horde_progress, 0.0, 1.0) # смешиваем
	var step_boost: float = minf(0.25, 0.03 * float(horde_index)) # надбавка за номер
	var final_t: float = clampf(combined + step_boost, 0.0, 1.0) # итоговый t
	return int(lerpf(float(min_enemies_horde), float(max_enemies_horde), final_t)) # цель толпы

func _is_horde_active() -> bool:
	if session_timer < first_horde_time: # ещё рано
		return false # нет толпы
	var since_first: float = session_timer - first_horde_time # прошло после первой
	return fmod(since_first, horde_interval) < horde_duration # в окне толпы?

func _get_alive_enemies() -> int:
	var nodes := get_tree().get_nodes_in_group("Enemies") # все враги
	return nodes.size() # их число

func _spawn_enemy_around_player() -> void:
	if enemy_scene == null or player == null: # нет данных
		return # выходим
	var enemy := enemy_scene.instantiate() as Node2D # инстансим
	if enemy == null: # не создался
		return # выходим
	get_tree().current_scene.add_child(enemy) # добавляем
	enemy.add_to_group("Enemies") # в группу
	var angle: float = randf() * TAU # угол
	var safe_radius: float = maxf(1.0, spawn_distance - min_offset) # защита от нуля
	var offset: float = min_offset + randf() * safe_radius # радиус появления
	var spawn_pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * offset # точка спавна
	enemy.global_position = spawn_pos # ставим

func _recycle_far_enemies() -> void:
	if player == null: # нет игрока
		return # выходим
	var nodes := get_tree().get_nodes_in_group("Enemies") # список
	if nodes.is_empty(): # пусто
		return # выходим
	var recycled := 0 # счётчик
	for n in nodes: # цикл
		if recycled >= max_recycles_per_tick: # достигли лимита
			break # стоп
		var enemy := n as Node2D # приводим
		if enemy == null: # не враг
			continue # пропуск
		var dist: float = player.global_position.distance_to(enemy.global_position) # расстояние
		if dist > respawn_radius: # слишком далеко
			enemy.queue_free() # удаляем
			_spawn_enemy_around_player() # создаём рядом
			recycled += 1 # считаем



#extends Node2D # узел для спавна врагов
#
#@export var enemy_scene: PackedScene # сцена врага
#
#var spawn_distance := 400.0 # максимум от игрока
#var min_offset := 300.0 # минимум от игрока
#
#var min_enemies_normal := 30 # старт обычной волны
#var max_enemies_normal := 30000 # конец обычной волны
#
#var first_horde_time := 60.0 # время первой толпы
#var horde_interval := 120.0 # период толпы
#var horde_duration := 20.0 # длительность толпы
#
#var min_enemies_horde := 120 # старт толпы
#var max_enemies_horde := 100000 # конец толпы
#
#var base_spawn_interval := 0.4 # интервал обычной
#var horde_spawn_interval := 0.1 # интервал толпы
#var session_duration := 40.0 * 60.0 # длительность сессии
#var cap_concurrent_enemies := 500000 # лимит врагов
#
#@export var respawn_radius := 600.0 # радиус рецикла
#@export var max_recycles_per_tick := 8 # лимит рецикла/кадр
#
#var spawn_timer := 0.0 # таймер спавна
#var session_timer := 0.0 # таймер сессии
#
#var player: Node2D = null # ссылка на игрока
#
#func _ready() -> void:
	#player = get_tree().get_first_node_in_group("Player") as Node2D # ищем игрока
	#randomize() # включаем рандом
#
#func _process(delta: float) -> void:
	#if session_timer >= session_duration: # если сессия кончилась
		#return # выходим
	#session_timer += delta # накапливаем время
	#_handle_spawning(delta) # логика спавна
	#_recycle_far_enemies() # рецикл дальних
#
#func _handle_spawning(_delta: float) -> void:
	#spawn_timer += _delta # накапливаем таймер
	#var interval := horde_spawn_interval if _is_horde_active() else base_spawn_interval # активный интервал
	#if spawn_timer < interval: # если рано
		#return # ждём
	#spawn_timer = 0.0 # сбрасываем
#
	#if player == null or enemy_scene == null: # проверяем ссылки
		#player = get_tree().get_first_node_in_group("Player") as Node2D # пробуем найти
		#return # ждём кадр
#
	#var alive := _get_alive_enemies() # сколько живо
	#if alive >= cap_concurrent_enemies: # достигли лимита
		#return # стоп
#
	#if _is_horde_active(): # если толпа
		#if alive < _get_current_horde_target(): # не достигли цели
			#_spawn_enemy_around_player() # спавним
	#else: # обычная волна
		#if alive < _get_current_normal_target(): # не достигли цели
			#_spawn_enemy_around_player() # спавним
#
#func _get_current_normal_target() -> int:
	#var progress: float = clampf(session_timer / session_duration, 0.0, 1.0) # доля 0..1
	#return int(lerpf(float(min_enemies_normal), float(max_enemies_normal), progress)) # линейный рост
#
#func _get_current_horde_target() -> int:
	#var progress: float = clampf(session_timer / session_duration, 0.0, 1.0) # доля 0..1
	#return int(lerpf(float(min_enemies_horde), float(max_enemies_horde), progress)) # линейный рост
#
#func _is_horde_active() -> bool:
	#if session_timer < first_horde_time: # ещё рано
		#return false # нет толпы
	#var since_first := session_timer - first_horde_time # прошло после первой
	#return fmod(since_first, horde_interval) < horde_duration # в окне толпы?
#
#func _get_alive_enemies() -> int:
	#var nodes := get_tree().get_nodes_in_group("Enemies") # все враги
	#return nodes.size() # их число
#
#func _spawn_enemy_around_player() -> void:
	#if enemy_scene == null or player == null: # нет данных
		#return # выходим
	#var enemy := enemy_scene.instantiate() as Node2D # инстансим
	#if enemy == null: # не создался
		#return # выходим
	#get_tree().current_scene.add_child(enemy) # добавляем
	#enemy.add_to_group("Enemies") # в группу
	#var angle := randf() * TAU # угол
	#var offset := min_offset + randf() * (spawn_distance - min_offset) # радиус
	#var spawn_pos := player.global_position + Vector2(cos(angle), sin(angle)) * offset # точка
	#enemy.global_position = spawn_pos # ставим
#
#func _recycle_far_enemies() -> void:
	#if player == null: # нет игрока
		#return # выходим
	#var nodes := get_tree().get_nodes_in_group("Enemies") # список
	#if nodes.is_empty(): # пусто
		#return # выходим
	#var recycled := 0 # счётчик
	#for n in nodes: # цикл
		#if recycled >= max_recycles_per_tick: # достигли лимита
			#break # стоп
		#var enemy := n as Node2D # приводим
		#if enemy == null: # не враг
			#continue # пропуск
		#var dist := player.global_position.distance_to(enemy.global_position) # расстояние
		#if dist > respawn_radius: # слишком далеко
			#enemy.queue_free() # удаляем
			#_spawn_enemy_around_player() # создаём рядом
			#recycled += 1 # считаем
