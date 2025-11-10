extends CharacterBody2D

@export var collectible_scene: PackedScene = preload("res://scene/collectible/collectible_001.tscn")

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var death_fx_blood: GPUParticles2D = $GPUParticles2D
@onready var hitbox_collision: CollisionShape2D = $HitBox/CollisionShape2D
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

# --- Статы из GameStats ---
var max_speed: float = 80.0
var health: int = 100
var damage: int = 0

# --- Состояния ---
enum State { IDLE, RUN, HIT, DEATH }
var current_state: State = State.IDLE
var death_flag: bool = false
var invincible: bool = false

# --- Knockback ---
var is_knockback: bool = false
var knock_dir: Vector2 = Vector2.ZERO
var knock_speed: float = 0.0
var knock_decay: float = 2200.0

# --- Производительность ---
var player_ref: Node2D = null
var sleep_radius: float = 1400.0 # вне радиуса моб «спит»
var tick_slot: int = randi() % 3 # моб обновляет AI 1 раз в 3 кадра
var tick_counter: int = 0

# Для хранения ссылки на сцену
var main_scene: Node

func _ready() -> void:
	_update_stats_from_gamestats()
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("Player") as Node2D
	
	# Сохраняем ссылку на основную сцену
	main_scene = get_tree().current_scene

func _update_stats_from_gamestats() -> void:
	# Берем статы напрямую из GameStats
	if GameStats and GameStats.stats_eye_ball:
		max_speed = float(GameStats.stats_eye_ball["max_speed"])
		health = int(GameStats.stats_eye_ball["max_health"])
		damage = int(GameStats.stats_eye_ball["damage"])

# Включается из пула через call_deferred после add_child
func on_spawn_activated() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)
	current_state = State.IDLE
	death_flag = false
	invincible = false
	is_knockback = false
	knock_dir = Vector2.ZERO
	knock_speed = 0.0
	if hitbox_collision:
		hitbox_collision.disabled = false
	if anim_player:
		anim_player.stop()

func _physics_process(delta: float) -> void:
	# Усыпление по дистанции до игрока
	if player_ref:
		var dist2 := (player_ref.global_position - global_position).length_squared()
		var r2 := sleep_radius * sleep_radius
		if dist2 > r2:
			if is_physics_processing():
				_set_sleep(true)
			return
		else:
			if not is_physics_processing():
				_set_sleep(false)

	# Knockback приоритетен
	if is_knockback:
		var motion: Vector2 = knock_dir * knock_speed * delta
		move_and_collide(motion)
		knock_speed = max(knock_speed - knock_decay * delta, 0.0)
		if knock_speed <= 0.1:
			is_knockback = false
		if death_flag and current_state != State.DEATH:
			current_state = State.DEATH
		return

	# Слотирование апдейтов (экономия CPU)
	tick_counter = (tick_counter + 1) % 3
	var full_update := (tick_counter == tick_slot)

	# Машина состояний
	match current_state:
		State.IDLE:
			if full_update:
				_state_idle()
		State.RUN:
			_state_run(delta, full_update)
		State.HIT:
			if full_update:
				_state_hit()
		State.DEATH:
			if full_update:
				_state_death()

	# Форсируем переход в смерть
	if death_flag and current_state != State.DEATH:
		current_state = State.DEATH

func _state_idle() -> void:
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("Player") as Node2D
	if player_ref == null:
		if anim_player:
			anim_player.play("Idle")
		return
	current_state = State.RUN

func _state_run(delta: float, full_update: bool) -> void:
	var dir: Vector2 = _get_direction_to_player()
	if dir == Vector2.ZERO:
		current_state = State.IDLE
		return
	velocity = dir * max_speed
	if full_update:
		if dir.x != 0:
			anim_sprite.flip_h = dir.x < 0
			anim_sprite.position.x = -34 if dir.x < 0 else 34
		if anim_player:
			anim_player.play("Run")
	move_and_slide()

func _get_direction_to_player() -> Vector2:
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("Player") as Node2D
	if player_ref:
		var d: Vector2 = player_ref.global_position - global_position
		if d.length_squared() > 0.0001:
			return d.normalized()
	return Vector2.ZERO

func take_damage(amount: int) -> void:
	if invincible or death_flag:
		return
	health -= amount
	if anim_player:
		anim_player.play("Hit")
	if health <= 0:
		death_flag = true
		current_state = State.DEATH
	else:
		current_state = State.HIT

func _state_hit() -> void:
	velocity = Vector2.ZERO
	if anim_player:
		await anim_player.animation_finished
	if not death_flag:
		current_state = State.IDLE

func _state_death() -> void:
	if death_flag == false:
		death_flag = true
	if hitbox_collision:
		hitbox_collision.disabled = true
	if death_fx_blood:
		death_fx_blood.restart()
	if anim_player:
		anim_player.play("Death")
	velocity = Vector2.ZERO
	
	if anim_player:
		await anim_player.animation_finished
	
	# шанс дропа
	if collectible_scene != null and randf() < 0.8:
		_spawn_collectible()
	
	_despawn_or_free()

func _spawn_collectible() -> void:
	var collectible_scene = preload("res://scene/collectible/collectible_001.tscn")
	var c := collectible_scene.instantiate()
	
	# Используем тот же родительский нод, что и у моба
	var parent = get_parent()
	if parent and is_instance_valid(parent):
		parent.add_child(c)
		c.global_position = global_position

func apply_knockback(dir: Vector2, force: float) -> void:
	is_knockback = true
	knock_dir = dir.normalized()
	knock_speed = force

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	_despawn_or_free()

# --- Деспавн/возврат в пул и сброс ---

func _despawn_or_free() -> void:
	# уменьшить счётчик мобов
	if GameStats and GameStats.enemy_spawner and GameStats.enemy_spawner.has("count_mobs_in_screen"):
		GameStats.enemy_spawner["count_mobs_in_screen"] = max(0, int(GameStats.enemy_spawner["count_mobs_in_screen"]) - 1)

	# вернуть в пул
	if MobPool and MobPool.has_method("return_pool"):
		# УДАЛЯЕМ из группы перед возвратом в пул
		remove_from_group("Enemies")
		
		# Вызываем return_pool, который сам удалит из родителя
		MobPool.return_pool(self)
		_reset_for_reuse()
	else:
		# Если пула нет, удаляем обычным способом
		if get_parent():
			get_parent().remove_child(self)
		queue_free()

func _reset_for_reuse() -> void:
	_update_stats_from_gamestats()
	death_flag = false
	invincible = false
	is_knockback = false
	knock_dir = Vector2.ZERO
	knock_speed = 0.0
	current_state = State.IDLE
	if hitbox_collision:
		hitbox_collision.disabled = false
	if anim_player:
		anim_player.stop()
	visible = false
	set_process(false)
	set_physics_process(false)

# --- Sleep/awake ---

func _set_sleep(sleep: bool) -> void:
	if sleep:
		set_process(false)
		set_physics_process(false)
		if anim_player:
			anim_player.pause()
	else:
		set_process(true)
		set_physics_process(true)
		if anim_player:
			anim_player.playback_speed = 1.0
