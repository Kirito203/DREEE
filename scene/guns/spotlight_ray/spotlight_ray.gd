extends Node2D # главный узел луча — добавляется в игрока

signal request_target_enemy(ray: Node2D) # сигнал, по которому игрок даст ссылку на ближайшего врага

# параметры урона и скорости проигрывания анимации
var damage = GameStats.stats_player["attack"]["spotlight_ray"]["damage"]
var cast_speed = GameStats.stats_player["attack"]["spotlight_ray"]["speed_cast"]

# переменная для хранения врага (цели)
var target_enemy: Node2D = null
# последняя известная позиция врага (если он умер, луч остаётся направленным туда)
var last_known_position: Vector2 = Vector2.ZERO

func _ready():
	# запускаем анимацию луча со скоростью, зависящей от прокачки
	$Area2D/AnimationPlayer.set_speed_scale(cast_speed)
	# вызываем отложенный сигнал, чтобы игрок успел появиться в сцене
	call_deferred("_emit_signal")

func _process(_delta: float) -> void:
	# позиция самого луча (он сидит в игроке, так что это центр игрока)
	var ray_origin = global_position

	# если цель ещё жива — обновляем её текущую позицию
	if target_enemy != null and is_instance_valid(target_enemy):
		last_known_position = target_enemy.global_position

	# считаем направление от игрока (начала луча) к цели
	var direction = (last_known_position - ray_origin).normalized()
	var angle = direction.angle()

	# поворачиваем Area2D в сторону врага
	$Area2D.rotation = angle

func _emit_signal():
	# отправляем сигнал, чтобы игрок подключился и дал врага
	emit_signal("request_target_enemy", self)

# вызывается игроком, когда он получает сигнал
func set_target(enemy: Node2D) -> void:
	target_enemy = enemy # сохраняем цель
	if is_instance_valid(enemy): # если цель ещё жива
		last_known_position = enemy.global_position # сохраняем её позицию

func _on_timer_timeout() -> void:
	# удаляем луч из сцены, когда срабатывает таймер
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	# если в зону вошёл HitBox врага
	if area.name == "HitBox":
		var mob = area.get_parent() # поднимаемся до врага
		# проверяем, что это враг и у него есть метод получения урона
		if mob.is_in_group("Enemies") and mob.has_method("take_damage"):
			mob.take_damage(damage) # наносим урон
			#print("Урон лучом")
