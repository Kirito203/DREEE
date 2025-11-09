extends CharacterBody2D # делаем моба наследником CharacterBody2D

@export var collectible_scene: PackedScene = preload("res://scene/collectible/collectible_001.tscn") # сцена подбираемого предмета

@onready var anim_sprite = $AnimatedSprite2D # спрайт моба
@onready var anim_player = $AnimationPlayer # проигрыватель анимаций
@onready var Death_fx_blood = $GPUParticles2D # эффект крови при смерти

enum State {IDLE, DEATH, RUN, HIT} # перечисляем состояния моба
var current_state: State = State.IDLE # текущее состояние

var character_states = { # словарь соответствия состояния и функции
	State.IDLE: state_idle, # состояние ожидания
	State.DEATH: state_death, # состояние смерти
	State.RUN: state_run, # состояние бега
	State.HIT: state_hit # состояние получения урона
}

var max_speed = GameStats.stats_eye_ball["max_speed"] # скорость моба
var health = GameStats.stats_eye_ball["max_health"] # здоровье моба
var damage = GameStats.stats_eye_ball["damage"] # урон моба
var death = false # флаг смерти
var invincible = false # флаг неуязвимости

var check_hit_claw = false # проверка удара когтями
var check_hit_slash = false # проверка удара клинком

var is_knockback: bool = false # моб сейчас в отбрасывании
var knock_dir: Vector2 = Vector2.ZERO # направление откидывания
var knock_speed: float = 0.0 # текущая скорость отбрасывания
var knock_decay: float = 2200.0 # затухание скорости отбрасывания

var on_collision = false
var collision_mobs: Array[CharacterBody2D] = []

var player = null


func _physics_process(delta: float) -> void: # вызывается каждый кадр физики
	if is_knockback: # если моб отбрасывается
		var motion := knock_dir * knock_speed * delta # вектор движения
		move_and_collide(motion) # двигаем моба с коллизиями
		knock_speed = max(knock_speed - knock_decay * delta, 0.0) # уменьшаем скорость
		if knock_speed <= 0.1: # если скорость почти 0
			is_knockback = false # отключаем нок
		if death and current_state != State.DEATH: # если моб умер
			current_state = State.DEATH # переключаемся в смерть
		return # выходим, чтобы не выполнялся AI
	
	character_states[current_state].call() # вызываем функцию текущего состояния
	if death and current_state != State.DEATH: # если умер
		current_state = State.DEATH # переключаемся в смерть

func state_idle(): # состояние ожидания
	var player = get_tree().get_first_node_in_group("Player") as Node2D # ищем игрока
	if player == null: # если игрока нет
		anim_player.play("Idle") # проигрываем анимацию ожидания
	else: # если игрок найден
		current_state = State.RUN # переключаемся в бег

func state_run(): # состояние бега
	if is_knockback: return # если моб в отбрасывании, то не бежим
	var direction = get_direction_to_player() # получаем направление к игроку
	velocity = max_speed * direction # задаём скорость движения
	if direction.x != 0: # если игрок слева или справа
		anim_sprite.flip_h = direction.x < 0 # отражаем спрайт
		anim_sprite.position.x = -34 if direction.x < 0 else 34 # смещаем спрайт
	anim_player.play("Run") # проигрываем анимацию бега
	move_and_slide() # двигаем моба

func get_direction_to_player(): # возвращает направление на игрока
	var player = get_tree().get_first_node_in_group("Player") as Node2D # ищем игрока
	if player != null: # если игрок найден
		return (player.global_position - global_position).normalized() # нормализованный вектор
	return Vector2.ZERO # если игрока нет, возвращаем ноль

func take_damage(amount: int): # получение урона
	health -= amount # уменьшаем здоровье сразу
	anim_player.play("Hit") # проигрываем анимацию удара сразу
	if health <= 0: # если здоровье <= 0
		current_state = State.DEATH # переключаемся в смерть
	else: # иначе
		current_state = State.HIT # переключаемся в состояние урона

func state_hit(): # состояние получения урона
	velocity = Vector2.ZERO # останавливаем моба
	await anim_player.animation_finished # ждём конца анимации
	if not death: # если не умер
		current_state = State.IDLE # возвращаемся в ожидание

func state_death(): # состояние смерти
	if death: return # если уже умер, выходим
	death = true # ставим флаг смерти
	$HitBox/CollisionShape2D.disabled = true # отключаем хитбокс
	Death_fx_blood.restart() # включаем кровь
	anim_player.play("Death") # проигрываем анимацию смерти
	velocity = Vector2.ZERO # останавливаем движение
	await anim_player.animation_finished # ждём конца анимации
	if randf() < 0.8: # 80% шанс
		spawn_collectible() # создаём предмет
	queue_free() # удаляем моба

func spawn_collectible(): # создаём предмет
	if collectible_scene == null: return # если сцены нет, выходим
	var collectible = collectible_scene.instantiate() # создаём экземпляр
	get_parent().add_child(collectible) # добавляем в уровень
	collectible.global_position = global_position # ставим на позицию моба

func apply_knockback(dir: Vector2, force: float) -> void: # отбрасывание
	is_knockback = true # включаем нок
	knock_dir = dir.normalized() # задаём направление
	knock_speed = force # задаём силу

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free() # удаляем моба


func _on_collision_area_body_entered(body: CharacterBody2D) -> void:
	pass

func stop_or_exit():
	pass
