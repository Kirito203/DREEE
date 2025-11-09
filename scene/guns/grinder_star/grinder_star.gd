extends Node2D

@onready var area_grinder_star = $HitBox_grinder_star # зона коллизии

var radius = GameStats.stats_player["attack"]["grinder_star"]["radius"] # радиус орбиты
var speed_cast = GameStats.stats_player["attack"]["grinder_star"]["speed_cast"] # скорость вращения по кругу (рад/сек)
var speed_cast_sprites := 30.0 # скорость собственного вращения
var orbit_index := 0 # индекс в круговой схеме

var player_ref: Node2D = null # ссылка на игрока
var angle := 0.0 # текущий угол на орбите
var damage = GameStats.stats_player["attack"]["grinder_star"]["damage"] # урон одной звездой
var count_grinder_star = GameStats.stats_player["attack"]["grinder_star"]["count"] # кол-во звёзд
var size_elements_grinder_star = GameStats.stats_player["attack"]["grinder_star"]["size"] # размер звезды

# Параметры анимации появления
var spawn_time := 0.3 # время увеличения размера до нужного
var spawn_elapsed := 0.0 # время с момента появления
var target_scale := Vector2.ONE # конечный масштаб

func _ready() -> void:
	player_ref = get_parent() # берём ссылку на игрока
	angle = (TAU / max(1, count_grinder_star)) * orbit_index # вычисляем стартовый угол
	target_scale = Vector2.ONE * size_elements_grinder_star # задаём конечный размер
	scale = Vector2.ZERO # начинаем с нулевого размера

func setup(index: int, player: Node2D) -> void:
	orbit_index = index # сохраняем индекс
	player_ref = player # сохраняем ссылку на игрока
	angle = (TAU / max(1, count_grinder_star)) * orbit_index # стартовый угол

func _process(delta: float) -> void:
	# Плавная анимация появления
	if spawn_elapsed < spawn_time:
		spawn_elapsed += delta
		var t = clamp(spawn_elapsed / spawn_time, 0.0, 1.0)
		scale = target_scale * t

	if player_ref:
		angle += speed_cast * delta # вращение по кругу
		var offset = Vector2(cos(angle), sin(angle)) * radius # смещение по кругу
		global_position = (player_ref.global_position + Vector2(0, -10)) + offset # позиция вокруг игрока
		rotation += speed_cast_sprites * delta # вращение самой звезды

func _on_timer_timeout() -> void:
	queue_free() # удаляем звезду

func _on_hit_box_grinder_star_area_entered(area: Area2D) -> void:
	if area.name == "HitBox":
		var mob = area.get_parent()
		if mob.is_in_group("Enemies") and mob.has_method("take_damage"):
			mob.take_damage(damage)
