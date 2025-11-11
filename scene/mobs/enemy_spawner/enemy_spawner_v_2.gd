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


@export_category("Настройка волн")
# Параметры: сколько мобов в одной прямоугольной волне и сколько раз повторить
@export var count_mob_spawn_rectangle: int = 20
@export var count_wave_rect1: int = 2

@export_category("Ограничение колв-ва мобов")
# Ограничение общего числа мобов и текущий счётчик (берём из GameStats)
@export var max_count_mobs : int = 200
@export var count_mobs_in_screen: int = 0

# Зоны для волны 2 (радиальная)
@onready var area_wave_02 = $Area_spawn_wave_02
@onready var area_w2_rad01 = $Area_spawn_wave_02/Radial_001_wave_02
@onready var timer_spawn_wave_02 = $Area_spawn_wave_02/Timer_spawn_wave_02
@onready var timer_create_wave_02 = $Area_spawn_wave_02/Timer_create_wave_02

@export var count_mob_spawn_radial: int = 30
@export var count_wave_rad2: int = 5

# Настройка батча: сколько мобов спавним за один кадр при создании волны
const SPAWN_BATCH_SIZE: int = 6

# --- Optimization Settings ---
@export_category("Оптимизация спавна")
@export var max_spawns_per_frame: int = 5
@export var enable_dynamic_spawning: bool = false # Временно отключаем для теста

# --- Новые настройки для спавна перед игроком ---
@export_category("Для спавна перед игроком")
@export var enable_front_spawn: bool = true
@export var front_spawn_distance: float = 400.0  # Дистанция перед игроком для спавна
@export var front_spawn_width: float = 300.0     # Ширина области спавна перед игроком
@export var front_spawn_chance: float = 0.3      # Шанс спавна моба перед игроком

var current_spawns_this_frame: int = 0
var player_ref: Node2D = null

func _ready() -> void:
	# Инициализация статов
	_update_stats_from_gamestats()
	# Находим игрока
	player_ref = get_tree().get_first_node_in_group("Player") as Node2D

func _update_stats_from_gamestats() -> void:
	# Берем статы напрямую из GameStats
	if GameStats and GameStats.enemy_spawner:
		max_count_mobs = int(GameStats.enemy_spawner["max_count_mobs"])
		count_mobs_in_screen = int(GameStats.enemy_spawner["count_mobs_in_screen"])

func _process(_delta):
	# Сбрасываем счетчик спавнов каждый кадр
	current_spawns_this_frame = 0

# Спавнит моба через пул; обновляет GameStats
func spawn_mob(world_spawn_point: Vector2) -> void:
	# Проверяем, что мы в дереве сцены
	if not is_inside_tree():
		print("Spawner not in scene tree, cannot spawn")
		return
	
	# Лимит на спавн в одном кадре
	if current_spawns_this_frame >= max_spawns_per_frame:
		return
	
	# Берём актуальный счётчик из GameStats (источник истины)
	_update_stats_from_gamestats()
	
	if count_mobs_in_screen >= max_count_mobs:
		return

	# parent — контейнер для мобов; если его нет — используем текущую сцену
	var parent = mobs_parent
	if parent == null:
		# Если контейнер не установлен, используем корень сцены
		parent = get_tree().current_scene

	# Берём моба из пула и сразу добавляем в parent на нужную позицию
	var mob = mob_pool.get_and_add_mob(parent, world_spawn_point)
	if mob == null:
		print("Failed to get mob from pool")
		return

	# Передаем ссылку на основную сцену мобу
	if mob.has_method("set_main_scene"):
		mob.set_main_scene(get_tree().current_scene)

	# Помечаем как врага (группы удобны для поиска/логики)
	mob.add_to_group("Enemies")

	# Обновляем счётчик в GameStats
	count_mobs_in_screen += 1
	GameStats.enemy_spawner["count_mobs_in_screen"] = count_mobs_in_screen
	current_spawns_this_frame += 1

# --- НОВЫЕ ФУНКЦИИ ДЛЯ РАЗНОСТОРОННЕГО СПАВНА ---

# Создает волну из СЛУЧАЙНЫХ прямоугольников вокруг игрока
func create_random_rectangle_wave() -> void:
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("Player") as Node2D
		if player_ref == null:
			return
	
	var rectangles = [area_w1_rect01, area_w1_rect02, area_w1_rect03, area_w1_rect04]
	var spawned_in_frame: int = 0
	
	# Распределяем мобов по случайным прямоугольникам
	for i in range(count_mob_spawn_rectangle):
		# Выбираем случайный прямоугольник
		var random_rect = rectangles[randi() % rectangles.size()]
		var spawn_point = _get_random_point_in_rectangle(random_rect)
		
		spawn_mob(spawn_point)
		spawned_in_frame += 1

		# если набрали батч — уступаем кадр и сбрасываем счётчик
		if spawned_in_frame >= SPAWN_BATCH_SIZE:
			spawned_in_frame = 0
			await get_tree().process_frame

	# финальная уступка кадра
	if spawned_in_frame > 0:
		await get_tree().process_frame

# Получает случайную точку внутри прямоугольника
func _get_random_point_in_rectangle(rectangle_spawn: CollisionShape2D) -> Vector2:
	var rect: RectangleShape2D = rectangle_spawn.shape
	if rect == null:
		return Vector2.ZERO
	
	var half: Vector2 = rect.size * 0.5
	var random_local = Vector2(
		randf_range(-half.x, half.x),
		randf_range(-half.y, half.y)
	)
	
	return rectangle_spawn.global_transform * random_local

# --- НОВЫЕ ФУНКЦИИ ДЛЯ СПАВНА ПЕРЕД ИГРОКОМ ---

# Создает мобов перед игроком (в направлении его движения)
func create_front_spawn_wave() -> void:
	if player_ref == null or not enable_front_spawn:
		return
	
	var player_velocity = Vector2.ZERO
	# Получаем скорость игрока (если есть такой метод)
	if player_ref.has_method("get_velocity"):
		player_velocity = player_ref.get_velocity()
	elif player_ref is CharacterBody2D:
		player_velocity = player_ref.velocity
	
	# Если игрок стоит на месте, используем последнее направление взгляда
	var move_direction = player_velocity.normalized()
	if move_direction == Vector2.ZERO:
		# Если скорость нулевая, смотрим в направлении курсора или последнего движения
		move_direction = Vector2(1, 0)  # Направление по умолчанию
	
	var spawned_in_frame: int = 0
	
	for i in range(count_mob_spawn_rectangle):
		# Шанс спавна моба перед игроком
		if randf() < front_spawn_chance:
			var spawn_point = _get_front_spawn_point(move_direction)
			spawn_mob(spawn_point)
			spawned_in_frame += 1

		if spawned_in_frame >= SPAWN_BATCH_SIZE:
			spawned_in_frame = 0
			await get_tree().process_frame
	
	if spawned_in_frame > 0:
		await get_tree().process_frame

# Получает точку для спавна перед игроком
func _get_front_spawn_point(direction: Vector2) -> Vector2:
	if player_ref == null:
		return Vector2.ZERO
	
	# Основная точка перед игроком
	var base_point = player_ref.global_position + direction * front_spawn_distance
	
	# Добавляем случайное смещение по ширине
	var perpendicular = Vector2(-direction.y, direction.x)  # Перпендикулярный вектор
	var width_offset = perpendicular * randf_range(-front_spawn_width * 0.5, front_spawn_width * 0.5)
	
	return base_point + width_offset

# --- КОМБИНИРОВАННЫЕ ВОЛНЫ ---

# Комбинированная волна: мобы со всех сторон + перед игроком
func create_combined_wave() -> void:
	var spawned_in_frame: int = 0
	
	# Фаза 1: Мобы со всех сторон (случайные прямоугольники)
	for i in range(count_mob_spawn_rectangle / 2):  # Половина мобов
		var rectangles = [area_w1_rect01, area_w1_rect02, area_w1_rect03, area_w1_rect04]
		var random_rect = rectangles[randi() % rectangles.size()]
		var spawn_point = _get_random_point_in_rectangle(random_rect)
		
		spawn_mob(spawn_point)
		spawned_in_frame += 1

		if spawned_in_frame >= SPAWN_BATCH_SIZE:
			spawned_in_frame = 0
			await get_tree().process_frame
	
	# Фаза 2: Мобы перед игроком
	if enable_front_spawn:
		for i in range(count_mob_spawn_rectangle / 4):  # Четверть мобов
			if player_ref:
				var player_velocity = Vector2.ZERO
				if player_ref.has_method("get_velocity"):
					player_velocity = player_ref.get_velocity()
				elif player_ref is CharacterBody2D:
					player_velocity = player_ref.velocity
				
				var move_direction = player_velocity.normalized()
				if move_direction == Vector2.ZERO:
					move_direction = Vector2(1, 0)
				
				if randf() < front_spawn_chance:
					var spawn_point = _get_front_spawn_point(move_direction)
					spawn_mob(spawn_point)
					spawned_in_frame += 1

			if spawned_in_frame >= SPAWN_BATCH_SIZE:
				spawned_in_frame = 0
				await get_tree().process_frame
	
	if spawned_in_frame > 0:
		await get_tree().process_frame

# --- ПЕРЕРАБОТАННЫЕ СУЩЕСТВУЮЩИЕ ФУНКЦИИ ---

# Обрабатывает таймер создания волны 1 — теперь использует комбинированную волну
func _on_timer_create_wave_01_timeout() -> void:
	for i in range(count_wave_rect1):
		# Используем комбинированную волну вместо фиксированных прямоугольников
		create_combined_wave()

		# Ждём появления мобов
		timer_spawn_wave_01.start()
		await timer_spawn_wave_01.timeout

	# Перезапускаем таймер
	timer_create_wave_01.start()

# Создаёт радиальную волну; распределяет нагрузку по кадрам
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

# Таймер для радиальной волны
func _on_timer_create_wave_02_timeout() -> void:
	for i in range(count_wave_rad2):
		create_radial_wave(area_w2_rad01)
		timer_spawn_wave_02.start()
		await timer_spawn_wave_02.timeout
		
	timer_create_wave_02.start()
