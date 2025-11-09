extends Node2D

@onready var mob_pool = MobPool # Autoload
@onready var mobs_parent: Node = $MobsContainer # или get_tree().current_scene, если контейнер не нужен

@onready var area_wave_01 = $Area_spawn_wave_01
@onready var area_w1_rect01 = $Area_spawn_wave_01/CollisionShape2D_001
@onready var area_w1_rect02 = $Area_spawn_wave_01/CollisionShape2D_002
@onready var area_w1_rect03 = $Area_spawn_wave_01/CollisionShape2D_003
@onready var area_w1_rect04 = $Area_spawn_wave_01/CollisionShape2D_004
@onready var timer_spawn_wave_01 = $Area_spawn_wave_01/Timer_spawn_wave_01
@onready var timer_create_wave_01 = $Area_spawn_wave_01/Timer_create_wave_01

var count_mob_spawn_rectangle = 20
var count_wave_rect1 = 2

var max_count_mobs : int = GameStats.enemy_spawner["max_count_mobs"]
var count_mobs_in_screen: int = GameStats.enemy_spawner["count_mobs_in_screen"]

@onready var area_wave_02 = $Area_spawn_wave_02
@onready var area_w2_rad01 = $Area_spawn_wave_02/Radial_001_wave_02
@onready var timer_spawn_wave_02 = $Area_spawn_wave_02/Timer_spawn_wave_02
@onready var timer_create_wave_02 = $Area_spawn_wave_02/Timer_create_wave_02

var count_mob_spawn_radial = 30
var count_wave_rad2 = 5

func spawn_mob(world_spawn_point: Vector2):
	count_mobs_in_screen = GameStats.enemy_spawner["count_mobs_in_screen"]
	if count_mobs_in_screen >= max_count_mobs:
		return

	var parent := mobs_parent if mobs_parent != null else get_tree().current_scene
	var mob := mob_pool.get_and_add_mob(parent, world_spawn_point)
	if mob == null:
		return

	mob.add_to_group("Enemies")
	count_mobs_in_screen += 1
	GameStats.enemy_spawner["count_mobs_in_screen"] = count_mobs_in_screen

func create_rectangle_wave(rectangle_spawn: CollisionShape2D) -> void:
	var rect: RectangleShape2D = rectangle_spawn.shape
	if rect == null:
		return
	var half: Vector2 = rect.size * 0.5
	var c_x: int = 3
	var c_y: int = int(ceil(count_mob_spawn_rectangle / float(c_x)))
	var cell_x: float = rect.size.x / c_x
	var cell_y: float = rect.size.y / c_y

	for y in range(c_y):
		for x in range(c_x):
			var lx: float = -half.x + (x + 0.5) * cell_x
			var ly: float = -half.y + (y + 0.5) * cell_y
			var local: Vector2 = Vector2(lx, ly)
			var world: Vector2 = rectangle_spawn.global_transform * local
			spawn_mob(world)
		await get_tree().process_frame

func _on_timer_create_wave_01_timeout() -> void:
	for i in range(count_wave_rect1):
		create_rectangle_wave(area_w1_rect01)
		create_rectangle_wave(area_w1_rect02)
		create_rectangle_wave(area_w1_rect03)
		create_rectangle_wave(area_w1_rect04)
		timer_spawn_wave_01.start()
		await timer_spawn_wave_01.timeout
	timer_create_wave_01.start()

func create_radial_wave(radial_spawn: CollisionShape2D) -> void:
	var circle: CircleShape2D = radial_spawn.shape
	if circle == null:
		return
	var r: float = circle.radius
	var step: float = TAU / float(count_mob_spawn_radial)
	var start: float = 0.0

	for i in range(count_mob_spawn_radial):
		var ang: float = start + step * i
		var local := Vector2(r, 0.0).rotated(ang)
		var world: Vector2 = radial_spawn.global_transform * local
		spawn_mob(world)
		if i % 10 == 0:
			await get_tree().process_frame

func _on_timer_create_wave_02_timeout() -> void:
	for i in range(count_wave_rad2):
		create_radial_wave(area_w2_rad01)
		timer_spawn_wave_02.start()
		await timer_spawn_wave_02.timeout
	timer_create_wave_02.start()
