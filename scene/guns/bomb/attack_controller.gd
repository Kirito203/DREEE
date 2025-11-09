extends Node

@onready var timer_bears_paw = $Timer_bears_paw
@onready var timer_spotlight_ray = $Timer_spotlight_raw
@onready var timer_grinder_star = $Timer_grinder_star
@onready var timer_thunderweb = $Timer_thunderweb
@onready var timer_blade_yoyo = $Timer_blade_yoyo
@onready var timer_groundwave = $Timer_groundwave
@onready var timer_frisbee = $Timer_frisbee


@export var bomb: PackedScene
@export var bears_paw: PackedScene
@export var spotlight_ray: PackedScene
@export var grinder_star: PackedScene
@export var thunderweb: PackedScene
@export var blade_yoyo: PackedScene
@export var groundwave: PackedScene
@export var frisbee: PackedScene

var bomb_activated = false #активирует атаку бомбой
var bears_paw_activated = GameStats.stats_player["attack"]["bears_paw"]["activated"] #активирует атаку лапой
var spotlight_ray_activated = GameStats.stats_player["attack"]["spotlight_ray"]["activated"] #активирует атаку лучом
var grinder_star_activated = GameStats.stats_player["attack"]["grinder_star"]["activated"] #активирует звезду
var thunderweb_activated = GameStats.stats_player["attack"]["thunderweb"]["activated"] #активирует молнию
var blade_yoyo_activated = GameStats.stats_player["attack"]["blade_yoyo"]["activated"] #активирует йо-йо
var groundwave_activated = GameStats.stats_player["attack"]["groundwave"]["activated"] #активирует ударную волну
var frisbee_activated = GameStats.stats_player["attack"]["frisbee"]["activated"] #активирует фрисби

#Переменые frisbee
var count_frisbee = GameStats.stats_player["attack"]["frisbee"]["count"] # количество копий
var frisbee_wait_time := 0.04 # задержка между вылетами фрисби

#Переменные Grinder_star
var count_grinder_star = GameStats.stats_player["attack"]["grinder_star"]["count"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelUpManager.check_attack_activated.connect(on_check_attack_activated)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func on_check_attack_activated():
	# проверяем время при каждой прокачке
	timer_bears_paw.wait_time =  GameStats.stats_player["attack"]["bears_paw"]["time_wait"]
	timer_spotlight_ray.wait_time = GameStats.stats_player["attack"]["spotlight_ray"]["time_wait"]
	timer_grinder_star.wait_time = GameStats.stats_player["attack"]["grinder_star"]["time_wait"]
	timer_thunderweb.wait_time = GameStats.stats_player["attack"]["thunderweb"]["time_wait"]
	timer_blade_yoyo.wait_time = GameStats.stats_player["attack"]["blade_yoyo"]["time_wait"]
	timer_groundwave.wait_time = GameStats.stats_player["attack"]["groundwave"]["time_wait"]
	timer_frisbee.wait_time = GameStats.stats_player["attack"]["frisbee"]["time_wait"]
	
	#проверяем активацию атаки
	bomb_activated = false #активирует атаку бомбой
	bears_paw_activated = GameStats.stats_player["attack"]["bears_paw"]["activated"] #активирует атаку лапой
	spotlight_ray_activated = GameStats.stats_player["attack"]["spotlight_ray"]["activated"] #активирует атаку лучом
	grinder_star_activated = GameStats.stats_player["attack"]["grinder_star"]["activated"] #активирует звезду
	thunderweb_activated = GameStats.stats_player["attack"]["thunderweb"]["activated"] #активирует молнию
	blade_yoyo_activated = GameStats.stats_player["attack"]["blade_yoyo"]["activated"] #активирует йо-йо
	groundwave_activated = GameStats.stats_player["attack"]["groundwave"]["activated"] #активирует ударную волну
	frisbee_activated = GameStats.stats_player["attack"]["frisbee"]["activated"] #активирует фрисби

func _on_timer_timeout() -> void:
	var player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if player == null:
		return

#Атака бомбой
	if bomb_activated == true:
		var attack_instance = bomb.instantiate() as Node2D
		player.get_parent().add_child(attack_instance)
		attack_instance.global_position = player.global_position

# Атака лучом
func _on_timer_spotlight_raw_timeout() -> void:
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return
	if spotlight_ray_activated == true:
		var attack_instance = spotlight_ray.instantiate() as Node2D # создаём экземпляр луча из PackedScene
		#player.add_child(attack_instance) # добавляем лапу в качестве дочернего узла игроку
		#принимаем сигнал и вызываем метод внутри плеер
		if attack_instance.has_signal("request_target_enemy"): #проверяем наличие сигнала у объекта
			attack_instance.connect("request_target_enemy", Callable(player, "on_request_target_enemy")) #Подключаем сигнал луча к методу игрока
		player.add_child(attack_instance) # добавляем лапу в качестве дочернего узла игроку
		#player.get_parent().add_child(attack_instance) # добавляем луч в качестве дочернего узла игроку
		attack_instance.global_position = player.global_position + Vector2(0,-10) #передаем позицию луча

func _on_timer_bears_paw_timeout() -> void:
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return
	
# Атака лапой
	if bears_paw_activated == true:
		var attack_instance = bears_paw.instantiate() as Node2D # создаём экземпляр лапы из PackedScene
		player.add_child(attack_instance) # добавляем лапу в качестве дочернего узла игроку
		attack_instance.position = Vector2(attack_instance.offset_bear_paw_x * player.attack_facing_direction, 0) # позиционируем лапу в зависимости от направления атаки
		
		if attack_instance.has_method("set_player"): # если сцена лапы имеет метод set_player
			attack_instance.set_player(player) # передаём ссылку на игрока в лапу

func _on_timer_grinder_star_timeout() -> void:
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return
		
	# Проверка, активна ли атака звездами
	if grinder_star_activated:
		# Создаём 3 экземпляра звезды
		
		for i in range(count_grinder_star):
			var star = grinder_star.instantiate() as Node2D # Создаём экземпляр сцены
			player.add_child(star) # Присоединяем звезду к игроку (чтобы она следовала за ним)
			
			# Вызываем метод setup, чтобы задать номер и ссылку на игрока
			if star.has_method("setup"):
				star.setup(i, player)

func _on_timer_thunderweb_timeout() -> void:
	var player = get_tree().get_first_node_in_group("Player") as Node2D # получаем игрока
	if player == null:
		return # если игрока нет — выходим
		
	if thunderweb_activated: # если молния активна
		var web = thunderweb.instantiate() as Node2D # создаём молнию
		player.add_child(web) # добавляем к игроку
		web.global_position = player.global_position # позиция = игрок

func _on_timer_blade_yoyo_timeout() -> void:
	var player = get_tree().get_first_node_in_group("Player") as Node2D # находим игрока
	if player == null: # если не найден
		return # выходим
	
	if not blade_yoyo_activated: # если йо-йо выключен
		return # ничего не делаем
		
	var count = GameStats.stats_player["attack"]["blade_yoyo"]["count"] # берём число йо-йо
	
	for i in range(count): # создаём по счётчику
		var yoyo := blade_yoyo.instantiate() as Node2D # инстансим йо-йо сцену
		player.add_child(yoyo) # цепляем к игроку
		if yoyo.has_method("setup"): # есть метод setup?
			yoyo.setup(i, player) # передаём индекс и игрока

func _on_timer_groundwave_timeout() -> void:
	if groundwave_activated == true:
		var player = get_tree().get_first_node_in_group("Player") as Node2D #находим игрока
		if player != null: #если игрок существует
			var groundwave_child := groundwave.instantiate() #создает внутри переменной, сцену с ударной волной
			player.add_child(groundwave_child) #добавляет ударную волну к игроку
			groundwave_child.global_position = player.global_position #задаем координаты ударной волне
		else:
			return

func _on_timer_frisbee_timeout() -> void: # таймер фрисби
	if frisbee_activated == true: # если фрисби активна
		var player = get_tree().get_first_node_in_group("Player") as CharacterBody2D # находим игрока
		if player == null: return
		
		var dir: Vector2 = Vector2.ZERO # направление
		if player.has_method("get_last_movement_direction"):
			dir = player.get_last_movement_direction()
		if dir == Vector2.ZERO:
			dir = Vector2(player.attack_facing_direction, 0)
		dir = dir.normalized()
		
		var markers_root := player.get_node_or_null("SpawnAttackMarkers") as Node2D # контейнер маркеров
		if markers_root == null: return
		markers_root.rotation = dir.angle() # поворачиваем контейнер
		
		var markers: Array[Node2D] = [] # собираем всех детей-маркеров
		for child in markers_root.get_children():
			if child is Node2D:
				markers.append(child)
				
		if markers.is_empty(): return
		
		for i in range(count_frisbee): # спавним по счётчику
			var spawn_from := markers[i % markers.size()] # берём маркер по кругу 1→2→…→5→1
			var spawn_pos := spawn_from.global_position
			
			var frisbee_child := frisbee.instantiate()
			player.get_parent().add_child(frisbee_child)
			frisbee_child.global_position = spawn_pos
			if frisbee_child.has_method("setup"):
				frisbee_child.setup(dir, player)
				
			if i < count_frisbee - 1:
				await get_tree().create_timer(frisbee_wait_time).timeout
