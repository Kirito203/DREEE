extends Node2D

@export var mob_eye_ball_01 : PackedScene = preload("res://scene/mobs/eye_ball/eye_ball_v2.tscn") #предзагрузка файла моба

#переменные для 1-й волны, в зонах прямоугольников вокруг игрока
@onready var area_wave_01 = $Area_spawn_wave_01
@onready var area_w1_rect01 = $Area_spawn_wave_01/CollisionShape2D_001
@onready var area_w1_rect02 = $Area_spawn_wave_01/CollisionShape2D_002
@onready var area_w1_rect03 = $Area_spawn_wave_01/CollisionShape2D_003
@onready var area_w1_rect04 = $Area_spawn_wave_01/CollisionShape2D_004
@onready var timer_spawn_wave_01 = $Area_spawn_wave_01/Timer_spawn_wave_01
@onready var timer_create_wave_01 = $Area_spawn_wave_01/Timer_create_wave_01

var count_mob_spawn_rectangle = 20 #кол-во мобов, которые спаунятся во время 1-й волны внутри 1-й зоны
var count_wave_rect1 = 2 #кол-во волн

var max_count_mobs : int = GameStats.enemy_spawner["max_count_mobs"]
var count_mobs_in_screen: int = GameStats.enemy_spawner["count_mobs_in_screen"]

#переменные для 2-й волны, радиально вокруг игрока
@onready var area_wave_02 = $Area_spawn_wave_02
@onready var area_w2_rad01 = $Area_spawn_wave_02/Radial_001_wave_02
@onready var timer_spawn_wave_02 = $Area_spawn_wave_02/Timer_spawn_wave_02
@onready var timer_create_wave_02 = $Area_spawn_wave_02/Timer_create_wave_02

var count_mob_spawn_radial = 30
var count_wave_rad2 = 5 #кол-во волн 

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

#функция спауна моба на нужной точке, эти точки присылают функции создания точек в облостях ниже
func spawn_mob(world_spawn_point: Vector2):
	count_mobs_in_screen = GameStats.enemy_spawner["count_mobs_in_screen"]
	if count_mobs_in_screen < max_count_mobs:
		var mob := mob_eye_ball_01.instantiate() #создаем копию сцены моба
		get_tree().current_scene.add_child(mob) #добавляем моба на сцену
		mob.global_position = world_spawn_point #располагаем моба в нужной позиции
		mob.add_to_group("Enemies")
		count_mobs_in_screen += 1 
		GameStats.enemy_spawner["count_mobs_in_screen"] = count_mobs_in_screen
	else:
		return

#функция создания точек в прямоугольниках
func create_rectangle_wave(rectangle_spawn:CollisionShape2D):
	var rectangle_zone_shape : RectangleShape2D = rectangle_spawn.shape #Достаем переменную shape нашего прямоугольника
	if rectangle_zone_shape == null: #если не вышло, все пропускаем
		return
	var half_rectangle: Vector2 = rectangle_zone_shape.size * 0.5 #Теперь получаем половину каждой из сторон этого прямоугольника
	
	var c_x: int = 3
	var c_y: int = ceil(count_mob_spawn_rectangle/c_x)
	
	var cell_x: float = rectangle_zone_shape.size.x/c_x
	var cell_y: float = rectangle_zone_shape.size.y/c_y
	
	for y in cell_x:
		for x in cell_y:
			#достаем рандомную точку внутри размеров прямоугольника
			
			#рандомное расположение в прямоугольнике
			#var lx :float = randf_range(-half_rectangle.x, half_rectangle.x) #по x
			#var ly :float = randf_range(-half_rectangle.y, half_rectangle.y) #по y
			
			var lx: float = -half_rectangle.x + (x + 0.5) * cell_x
			var ly: float = -half_rectangle.y + (y + 0.5) * cell_y
			
			var local_spawn_point : Vector2 = Vector2(lx, ly) #получили точку внутри координат прямоугольника
			#переводим координаты из локальных в глобальные с учетом поворота и размера
			var world_spawn_point : Vector2 = rectangle_spawn.global_transform * local_spawn_point
			# отправляем координату в функцию спауна моба
			spawn_mob(world_spawn_point)

#запускает спаун точек в прямоугольниках по таймеру в соответствии с кол-ом волн
func _on_timer_create_wave_01_timeout() -> void:
	for i in count_wave_rect1:
		if mob_eye_ball_01 != null:
			create_rectangle_wave(area_w1_rect01) #передаем сам узел прямоугольника
			create_rectangle_wave(area_w1_rect02)
			create_rectangle_wave(area_w1_rect03)
			create_rectangle_wave(area_w1_rect04)
			timer_spawn_wave_01.start()
			await timer_spawn_wave_01.timeout
		else:
			print ("Нет сцены с мобом")
			return
	timer_create_wave_01.start()


#функция для создания точек по радиусу, который создан в сцене
func create_radial_wave(radial_spawn:CollisionShape2D):
	var circle : CircleShape2D = radial_spawn.shape
	if circle == null:
		return
	var radius_circle: float = circle.radius #достаем радиус круга
	
	var angle_step: float = TAU / float(count_mob_spawn_radial) #поделили окружность на кол-во мобов, чтобы расставить их по радиусу (TAU это полная окружность 360 PI половина 180)
	var start_angle: float = 0.0 #стартовая точка с оторой начинаем расставлять
	
	for i in count_mob_spawn_radial:
		var angle_point: float = start_angle + angle_step * i #делаем смещение на нужный градус, умножаем на шаг, чтобы расставить мобов ровно
		var local_point: Vector2 = Vector2(radius_circle, 0.0).rotated(angle_point) #мы отставляем точку на радиус окружности и поворачиваем её при помощи функции rotated(сюда пишем градус на которой поворачиваем)
		var world_spawn_point : Vector2 = radial_spawn.global_transform * local_point
		spawn_mob(world_spawn_point)

#по таймеру запускает функцию расстановки точек несколько раз, в зависимости от волн
func _on_timer_create_wave_02_timeout() -> void:
	for i in count_wave_rad2:
		if mob_eye_ball_01 != null:
			create_radial_wave(area_w2_rad01) #передаем сам узел радиальной зоны
			timer_spawn_wave_02.start()
			await timer_spawn_wave_02.timeout
		else:
			print ("Нет сцены с мобом")
			return
