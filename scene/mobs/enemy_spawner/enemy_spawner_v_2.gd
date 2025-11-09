extends Node2D

# Autoload пул (MobPool) — должен быть добавлен в Project Settings → Autoload с именем MobPool
@onready var mob_pool = MobPool

# Контейнер для активных мобов в сцене (делает дерево чище и ускоряет поиск)
@onready var mobs_parent: Node = $MobsContainer

# Зоны для волны 1 (прямоугольные области вокруг игрока)
@onready var area_wave_01 = $Area_spawn_wave_01
@onready var area_w1_rect01 = $Area_spawn_wave_01/CollisionShape2D_001
@onready var area_w1_rect02 = $Area_spawn_wave_01/CollisionShape2D_002
@onready var area_w1_rect03 = $Area_spawn_wave_01/CollisionShape2D_003
@onready var area_w1_rect04 = $Area_spawn_wave_01/CollisionShape2D_004

# Таймеры для управления интервалами между партиями и волнами
@onready var timer_spawn_wave_01 = $Area_spawn_wave_01/Timer_spawn_wave_01
@onready var timer_create_wave_01 = $Area_spawn_wave_01/Timer_create_wave_01

# Параметры: сколько мобов в одной прямоугольной волне и сколько раз повторить
@export var count_mob_spawn_rectangle: int = 20
@export var count_wave_rect1: int = 2

# Ограничение общего числа мобов и текущий счётчик (берём из GameStats)
var max_count_mobs : int = int(GameStats.enemy_spawner["max_count_mobs"])
var count_mobs_in_screen: int = int(GameStats.enemy_spawner["count_mobs_in_screen"])

# Зоны для волны 2 (радиальная)
@onready var area_wave_02 = $Area_spawn_wave_02
@onready var area_w2_rad01 = $Area_spawn_wave_02/Radial_001_wave_02
@onready var timer_spawn_wave_02 = $Area_spawn_wave_02/Timer_spawn_wave_02
@onready var timer_create_wave_02 = $Area_spawn_wave_02/Timer_create_wave_02

@export var count_mob_spawn_radial: int = 30
@export var count_wave_rad2: int = 5

# Настройка батча: сколько мобов спавним за один кадр при создании волны
@export const SPAWN_BATCH_SIZE: int = 6

# Спавнит моба через пул; обновляет GameStats
func spawn_mob(world_spawn_point: Vector2) -> void:
	# Берём актуальный счётчик из GameStats (источник истины)
	count_mobs_in_screen = int(GameStats.enemy_spawner["count_mobs_in_screen"])
	if count_mobs_in_screen >= max_count_mobs:
		return

	# parent — контейнер для мобов; если его нет — используем текущую сцену
	var parent := mobs_parent if mobs_parent != null else get_tree().current_scene

	# Берём моба из пула и сразу добавляем в parent на нужную позицию
	var mob := mob_pool.get_and_add_mob(parent, world_spawn_point)
	if mob == null:
		return

	# Помечаем как врага (группы удобны для поиска/логики)
	mob.add_to_group("Enemies")

	# Обновляем счётчик в GameStats
	count_mobs_in_screen += 1
	GameStats.enemy_spawner["count_mobs_in_screen"] = count_mobs_in_screen

# Создаёт точки спавна равномерно внутри прямоугольника; распределяет нагрузку по кадрам
func create_rectangle_wave(rectangle_spawn: CollisionShape2D) -> void:
	var rect: RectangleShape2D = rectangle_spawn.shape
	if rect == null:
		return

	var half: Vector2 = rect.size * 0.5
	var c_x: int = 3
	var c_y: int = int(ceil(float(count_mob_spawn_rectangle) / float(c_x)))
	var cell_x: float = rect.size.x / float(c_x)
	var cell_y: float = rect.size.y / float(c_y)

	var spawned_in_frame: int = 0

	for y in range(c_y):
		for x in range(c_x):
			var lx: float = -half.x + (x + 0.5) * cell_x
			var ly: float = -half.y + (y + 0.5) * cell_y
			var local: Vector2 = Vector2(lx, ly)
			var world: Vector2 = rectangle_spawn.global_transform * local

			spawn_mob(world)
			spawned_in_frame += 1

			# если набрали батч — уступаем кадр и сбрасываем счётчик
			if spawned_in_frame >= SPAWN_BATCH_SIZE:
				spawned_in_frame = 0
				await get_tree().process_frame

	# финальная уступка кадра для ровного распределения (можно убрать при малом числе)
	if spawned_in_frame > 0:
		await get_tree().process_frame

# Обрабатывает таймер создания волны 1 — последовательно создаёт c_x зон и ждёт между партиями
func _on_timer_create_wave_01_timeout() -> void:
	for i in range(count_wave_rect1):
		# Каждая зона создаёт свою подволну; create_rectangle_wave сама распределяет нагрузку
		create_rectangle_wave(area_w1_rect01)
		create_rectangle_wave(area_w1_rect02)
		create_rectangle_wave(area_w1_rect03)
		create_rectangle_wave(area_w1_rect04)

		# Ждём появления мобов (таймер отвечает за интервалы между партиями в волне)
		timer_spawn_wave_01.start()
		await timer_spawn_wave_01.timeout

	# После всех повторов — перезапускаем таймер создания волны (если нужно)
	timer_create_wave_01.start()

# Создаёт радиальную волну; распределяет нагрузку по кадрам (каждые 10 мобов)
func create_radial_wave(radial_spawn: CollisionShape2D) -> void:
	var circle: CircleShape2D = radial_spawn.shape
	if circle == null:
		return
	var r: float = circle.radius
	var step: float = TAU / float(count_mob_spawn_radial)
	var start: float = 0.0

	var spawned_in_frame: int = 0

	for i in range(count_mob_spawn_radial):
		var ang: float = start + step * i
		var local := Vector2(r, 0.0).rotated(ang)
		var world: Vector2 = radial_spawn.global_transform * local

		spawn_mob(world)
		spawned_in_frame += 1

		if spawned_in_frame >= SPAWN_BATCH_SIZE:
			spawned_in_frame = 0
			await get_tree().process_frame

	# финальная уступка
	if spawned_in_frame > 0:
		await get_tree().process_frame

# Таймер для радиальной волны; создаёт несколько повторов волны с интервалом
func _on_timer_create_wave_02_timeout() -> void:
	for i in range(count_wave_rad2):
		create_radial_wave(area_w2_rad01)
		timer_spawn_wave_02.start()
		await timer_spawn_wave_02.timeout
	timer_create_wave_02.start()
