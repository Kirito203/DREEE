extends CharacterBody2D # делаем моба наследником CharacterBody2D

@export var collectible_scene: PackedScene = preload("res://scene/collectible/collectible_001.tscn") # сцена подбираемого предмета

@onready var anim_sprite = $AnimatedSprite2D # спрайт моба
@onready var anim_player = $AnimationPlayer # проигрыватель анимаций
@onready var Death_fx_blood = $GPUParticles2D # эффект крови при смерти

var max_speed = GameStats.stats_eye_ball["max_speed"] # скорость моба
var health = GameStats.stats_eye_ball["max_health"] # здоровье моба
var damage = GameStats.stats_eye_ball["damage"] # урон моба
var death = false # флаг смерти
var invincible = false # флаг неуязвимости

var on_collision = false
var collision_mobs: Array[CharacterBody2D] = []

var player = null

func _ready() -> void:
	pass

func _process(delta: float) -> void: # вызывается каждый кадр физики
	var direction = get_direction_to_player()
	velocity = max_speed * direction
	#global_position += velocity * delta
	if direction.x != 0: # если игрок слева или справа
		flip_direction(direction)
	move_and_slide()

func flip_direction(direction):
	anim_sprite.flip_h = direction.x < 0 # отражаем спрайт
	anim_sprite.position.x = -34 if direction.x < 0 else 34 # смещаем спрайт

func get_direction_to_player():
	var player = get_tree().get_first_node_in_group("Player")
	if player != null:
		return (player.global_position - global_position).normalized()
	return Vector2(0,0)

func take_damage(amount: int): # получение урона
	health -= amount # уменьшаем здоровье сразу
	if health <= 0: # если здоровье <= 0
		take_death()
	else:
		anim_player.play("Hit") # проигрываем анимацию удара сразу
		set_process(false)
		velocity = Vector2.ZERO
		await anim_player.animation_finished
		anim_player.play("Run")
		set_process(true)

func take_death():
	GameStats.enemy_spawner["count_mobs_in_screen"] -= 1
	Death_fx_blood.restart() # включаем кровь
	set_process(false)
	anim_player.play("Death")
	await anim_player.animation_finished
	queue_free()

func _on_collision_area_body_entered(body: CharacterBody2D) -> void:
	pass

func stop_or_exit():
	pass
