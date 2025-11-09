extends Node2D # генератор молнии

@export var lightning_segment_scene: PackedScene # сцена одного сегмента молнии

var random_angle_branch = randf_range(0.5, 2) # множитель для случайного угла отклонения
var angle_branch = GameStats.stats_player["attack"]["thunderweb"]["angle_branch"] # базовый угол между ветками
var damage: int = GameStats.stats_player["attack"]["thunderweb"]["damage"] # урон молнии
var length_segment = GameStats.stats_player["attack"]["thunderweb"]["length_segment"] # длина одного сегмента
var random_length_segment = randf_range(1, 1.5) # рандомный диапазон для длины сегмента
var first_count_branch = GameStats.stats_player["attack"]["thunderweb"]["first_count_branch"] # число начальных веток
var count_branch = GameStats.stats_player["attack"]["thunderweb"]["count_branch"] # число подветок на каждом шаге
var count_steps = GameStats.stats_player["attack"]["thunderweb"]["count_steps"] # число ступеней ветвления

var root_direction: Vector2 = Vector2.RIGHT # направление по умолчанию
var rotate_player_last: Vector2 = Vector2.RIGHT # последнее направление игрока

func _ready():
	var player = get_tree().get_first_node_in_group("Player") as CharacterBody2D # ищем игрока
	if player != null and player.has_method("get_last_movement_direction"): # проверяем метод у игрока
		rotate_player_last = player.get_last_movement_direction() # берём последнее направление движения
	generate_thunderweb() # запускаем генерацию молнии

func generate_thunderweb():
	var branches = [] # список концов веток
	
	#var angle_offset = angle_branch * random_angle_branch # общий угол отклонения
	
	for i in range(first_count_branch): # цикл по количеству первых веток
		var angle := 0.0 # начальный угол
		
		if first_count_branch > 1: # если больше одной ветки
			var local_angle_offset = angle_branch * random_angle_branch # случайный угол
			angle = -local_angle_offset + i * (2.0 * local_angle_offset / max(1, first_count_branch - 1)) # распределяем по дуге
			
		var branch_dir = rotate_player_last.rotated(angle) # направление ветки
		
		var segment = lightning_segment_scene.instantiate() # создаём сегмент
		segment.scale = Vector2(length_segment, 1) # масштабируем сегмент по длине (как было у тебя)
		get_parent().add_child(segment) # добавляем сегмент в сцену
		
		var end_pos = segment.set_points(global_position, branch_dir) # ставим начало сегмента и получаем конец
		
		branches.append({ # сохраняем конец и направление
			"end": end_pos,
			"dir": branch_dir
		})
		
	for branch in branches: # обрабатываем каждую ветку
		generate_branch_step(branch["end"], branch["dir"], count_steps - 1) # создаём подветки

func generate_branch_step(start_pos: Vector2, direction: Vector2, depth: int):
	if depth <= 0: # если достигли лимита глубины
		return
		
	var angle_offset = angle_branch * randf_range(0.5, 2.0) # случайный угол
	
	for i in range(count_branch): # цикл по количеству подветок
		await get_tree().create_timer(0.015).timeout # задержка для "рисования" молнии
		
		var angle = -angle_offset + i * (2.0 * angle_offset / max(1, count_branch - 1)) # распределяем угол
		var new_dir = direction.rotated(angle) # новое направление ветки
		
		var segment = lightning_segment_scene.instantiate() # создаём сегмент
		segment.scale = Vector2(length_segment * random_length_segment, 1) # масштабируем сегмент по длине
		get_parent().add_child(segment) # добавляем сегмент в сцену
		
		var end_pos = segment.set_points(start_pos, new_dir) # ставим начало сегмента и получаем конец
		
		generate_branch_step(end_pos, new_dir, depth - 1) # рекурсия для подветок
