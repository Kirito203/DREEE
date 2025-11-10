extends Area2D

var tween: Tween
var move_speed: float = 300.0  # Значение по умолчанию
var xp_up: int = 20  # Значение по умолчанию
# скорость притягивания — задаётся в инспекторе

var target_player: Node2D = null 
# сюда мы сохраним игрока, к которому тянется предмет
@onready var collision_shape = $CollisionShape2D
var collected := false

func _ready() -> void:
	# Получаем значения из GameStats, если он доступен
	_update_stats_from_gamestats()

func _update_stats_from_gamestats() -> void:
	if GameStats and GameStats.stats_collectibles:
		move_speed = float(GameStats.stats_collectibles.get("max_speed", 300))
		xp_up = int(GameStats.stats_collectibles.get("xp_up_low", 20))

func _process(delta): # вызывается каждый кадр
	if collected:
		return # если уже собирается — не двигаться
	
	if target_player and is_instance_valid(target_player): # если есть цель и она существует
		var direction = (target_player.global_position - global_position).normalized()# направление от предмета к игроку
		position += direction * move_speed * delta # двигаем предмет в сторону игрока


func start_following(player: Node2D): # этот метод вызывается из игрока
	target_player = player # сохраняем ссылку на игрока как цель


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): # проверяем, что вошёл игрок
		animate_and_destroy()

func animate_and_destroy():
	collected = true
	
	# Обновляем статы перед использованием
	_update_stats_from_gamestats()
	
	# Прибавляем опыт игроку
	if GameStats and GameStats.stats_player:
		GameStats.stats_player["current_xp"] += xp_up 
		# Проверяем, достиг ли уровень апгрейда
		GameStats.check_level_up()
	else:
		print("GameStats not available for XP collection")

	var tween_instance = create_tween() # создаём новый tween
	
	# одновременно уменьшаем и поднимаем
	tween_instance.tween_property(self, "position:y", position.y - 80, 0.2)
	tween_instance.tween_property(self, "scale", scale * 0.3, 0.1)

	# затем — задержка и удаление
	tween_instance.tween_interval(0.3)
	tween_instance.tween_callback(queue_free)
