extends Node2D # узел одного сегмента молнии

@onready var area = $Area2D # область столкновения
@onready var shape = $Area2D/CollisionShape2D # коллизия сегмента
@onready var fx_thunder = $GPUParticles2D # партиклы молнии
@onready var anim = $Area2D/AnimatedSprite2D # спрайт молнии
@onready var end_marker = $Area2D/EndMarker # конечная точка сегмента

var damage: int = GameStats.stats_player["attack"]["thunderweb"]["damage"] # урон молнии
var length_segment = GameStats.stats_player["attack"]["thunderweb"]["length_segment"] # длина сегмента молнии

func _ready():
	fx_thunder.restart() # перезапуск партиклов
	anim.play("Attack") # проигрываем анимацию молнии

# Устанавливаем сегмент и возвращаем Marker2D (конечную точку)
func set_points(start: Vector2, direction: Vector2) -> Vector2:
	direction = direction.normalized() # нормализуем направление
	global_position = start # ставим сегмент в стартовую точку
	rotation = direction.angle() # поворачиваем сегмент в нужную сторону
	return end_marker.global_position # возвращаем позицию конца сегмента

func _on_timer_timeout() -> void:
	queue_free() # удаляем сегмент по таймеру

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "HitBox": # проверяем, что это хитбокс врага
		var mob = area.get_parent() # получаем моба
		if mob.is_in_group("Enemies") and mob.has_method("take_damage"): # если это враг
			mob.take_damage(damage) # наносим урон
