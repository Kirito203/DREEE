extends Node2D

@onready var area = $Area2D # зона коллизии
@onready var life_timer: Timer = $Timer # таймер жизни йо-йо

var speed_high_move = GameStats.stats_player["attack"]["blade_yoyo"]["speed_high_move"] # скорость роста радиуса
var speed_radial_move = GameStats.stats_player["attack"]["blade_yoyo"]["speed_radial_move"] # угловая скорость (рад/сек)
var speed_cast_sprites := -20.0 # скорость собственного вращения спрайта
var orbit_index := 0 # индекс в пачке (0..count-1)

var damage = GameStats.stats_player["attack"]["blade_yoyo"]["damage"] # урон йо-йо
var count_yoyo = GameStats.stats_player["attack"]["blade_yoyo"]["count"] # количество йо-йо
var size_elements_blade_yoyo = GameStats.stats_player["attack"]["blade_yoyo"]["size"] # размер элементов йо-йо

@export var max_radius: float = 200.0 # максимальный радиус движения
var current_radius := 0.0 # текущий радиус спирали

var player_ref: Node2D = null # ссылка на игрока
var angle := 0.0 # текущий угол на орбите

var direction_sign := 1 # направление вращения (+1 или -1)
var random_radial_mult := 1.0 # множитель скорости вращения (рандом)
var random_high_mult := 1.0   # множитель скорости отдаления (рандом)

# Параметры анимации появления
var spawn_time := 0.3 # время увеличения размера (сек)
var spawn_elapsed := 0.0 # время с момента появления
var target_scale := Vector2.ONE # конечный масштаб (зависит от size_elements_blade_yoyo)

func _ready() -> void:
	player_ref = get_parent() # получаем ссылку на игрока
	angle = (TAU / max(1, count_yoyo)) * orbit_index # вычисляем стартовый угол
	target_scale = Vector2.ONE * size_elements_blade_yoyo # задаём конечный размер
	scale = Vector2.ZERO # начинаем с нулевого размера

func setup(index: int, player: Node2D) -> void:
	orbit_index = index # сохраняем индекс
	player_ref = player # сохраняем ссылку на игрока
	var c = GameStats.stats_player["attack"]["blade_yoyo"]["count"] # берём кол-во йо-йо
	angle = (TAU / max(1, c)) * orbit_index # задаём стартовый угол
	
	direction_sign = 1 if index % 2 == 0 else -1 # чётные по часовой, нечётные против часовой
	speed_cast_sprites *= direction_sign # вращаем спрайт в ту же сторону
	
	random_radial_mult = randf_range(1.0, 1.5) # случайный множитель вращения
	random_high_mult = randf_range(1.0, 1.5) # случайный множитель отдаления

func _process(delta: float) -> void:
	if spawn_elapsed < spawn_time: # если анимация появления ещё идёт
		spawn_elapsed += delta # увеличиваем время
		var t = clamp(spawn_elapsed / spawn_time, 0.0, 1.0) # нормализуем 0..1
		scale = target_scale * t # плавно увеличиваем размер

	area.rotation += speed_cast_sprites * delta # вращаем йо-йо вокруг своей оси
	angle += direction_sign * speed_radial_move * random_radial_mult * delta # увеличиваем угол
	current_radius = min(current_radius + speed_high_move * random_high_mult * delta, max_radius) # увеличиваем радиус

	if player_ref: # если игрок есть
		var offset = Vector2.RIGHT.rotated(angle) * current_radius # вычисляем смещение по окружности
		global_position = player_ref.global_position + offset # задаём позицию йо-йо

func _on_timer_timeout() -> void:
	queue_free() # удаляем йо-йо по таймеру

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "HitBox": # проверяем, что это хитбокс врага
		var mob = area.get_parent() # получаем моба
		if mob.is_in_group("Enemies") and mob.has_method("take_damage"): # проверяем группу и метод
			mob.take_damage(damage) # наносим урон
