extends Node2D

var player_ref: Node2D = null

@onready var anim_sprite = $AnimatedSprite2D
@onready var area_claw = $Sprite2D/HitBox_Claw
@onready var area_slash = $AnimatedSprite2D/HitBox_Slash

var damage = GameStats.stats_player["attack"]["bears_paw"]["damage"]
var cast_speed = GameStats.stats_player["attack"]["bears_paw"]["speed_cast"]

var direction_x := 1 #может быть 1 или -1
var offset_bear_paw_x = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_player(p):
	player_ref = p
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Если есть ссылка на игрока — обновляем направление спрайта лапы
	# Это позволяет атаке "следить" за разворотом игрока даже после появления
	if player_ref:
		scale = Vector2(player_ref.attack_facing_direction, 1) # Только по X: влево (-1) или вправо (1) # По Y всегда 1, чтобы лапа не сжималась
		position.x = offset_bear_paw_x * player_ref.attack_facing_direction # позиционируем лапу с учётом смещения

func set_flip_direction(new_dir_x):
	# Разворачиваем визуально
	direction_x = new_dir_x

func _on_timer_timeout() -> void:
	queue_free()

#атака от лапы
func _on_hit_box_claw_area_entered(area: Area2D) -> void:
	if area.name == "HitBox": # Узел моба, который может быть атакуем
		var mob = area.get_parent()
		if mob.is_in_group("Enemies") and mob.has_method("take_damage"):
			mob.take_damage(damage)  # Или stats_player["attack_bears_paw"]

func _on_hit_box_slash_area_entered(area: Area2D) -> void:
	if area.name == "HitBox": # Узел моба, который может быть атакуем
		var mob = area.get_parent()
		if mob.is_in_group("Enemies") and mob.has_method("take_damage"):
			mob.take_damage(damage)  # Или stats_player["attack_bears_paw"] 
