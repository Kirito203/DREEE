extends Node2D # узел волны

@onready var anim_player: AnimationPlayer = $HitBoxGroundwave/AnimationPlayer # анимация волны
@onready var hitbox: Area2D = $HitBoxGroundwave # хитбокс
@onready var shape: CollisionShape2D = $HitBoxGroundwave/CollisionShape2D # коллизия

@export var damage: int = GameStats.stats_player["attack"]["groundwave"]["damage"] # урон волны
@export var knockback_force: float = GameStats.stats_player["attack"]["groundwave"]["knockback_force"] # сила отбрасывания

var hit_once := {} # словарь для проверки, кого уже ударили

func _ready() -> void: # при запуске
	rotation_degrees = randf_range(0.0, 360.0) # задаём случайный угол вращения от 0 до 360
	anim_player.play("Attack_05") # проигрываем анимацию атаки

func _on_animation_player_animation_finished(anim_name: StringName) -> void: # при окончании анимации
	queue_free() # удаляем волну

func _on_hit_box_groundwave_area_entered(area: Area2D) -> void: # при входе объекта в хитбокс
	if area.name == "HitBox": # если это хитбокс врага
		var mob = area.get_parent() # получаем родителя (моба)
		if not mob.is_in_group("Enemies"): # если не враг
			return # выходим
		if hit_once.has(mob): # если уже били
			return # выходим
		hit_once[mob] = true # помечаем, что ударили

		if mob.has_method("take_damage"): # если у моба есть метод урона
			mob.take_damage(damage) # наносим урон сразу

		var dir: Vector2 = (mob.global_position - global_position).normalized() # направление от волны
		if mob.has_method("apply_knockback"): # если у моба есть метод отбрасывания
			mob.apply_knockback(dir, knockback_force) # применяем отбрасывание
