extends CharacterBody2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var ImmortalityTimer = $HurtBox/ImmortalityTimer
@onready var Level_up_fx = $GPUParticles2D
@onready var Level_up_screen = $"../../LevelUpScreen"
@onready var UI_Player = $"../../UI"
@onready var time_damage = $DamageTimer

#@export var level_up_fx_scene: PackedScene #fx повышения уровня

#signal level_up #сигнал повышения уровня #скрыл, потому что была ошибка, тестируем и удаляем
#signal level_up_fx #сигнал запуска fx #сигнал появления fx

var enemies_in_hurtbox: Array[Node2D] = [] # список врагов внутри
var attack_facing_direction = 1

var max_speed = GameStats.stats_player["max_speed"]
#var max_health = GameStats.stats_player["max_health"]
#var current_health = GameStats.stats_player["current_health"]
var death = false
var amount : int = 0 #Переменная для получения урона от мобов
var is_processing_hit = false #Переменная от спама урона в процессе состояния получения урона
var last_movement_direction: Vector2 = Vector2.RIGHT # хранит последнее направление движения
var enemies_in_EnemyScanArea: Array[Node2D] = [] # список врагов в радиусе

#StateMachine создаем перечисление, переменную с нужным состоянием, список с состояние - функция на которую будет ссылаться
enum State { IDLE, RUN, DEATH, HIT } #создаем перечисление состояний, автоматически присваивает 0, 1, 2, 3 и тд соотсветственно
var current_state : State = State.IDLE #создаем переменную с состоянием, в эту переменную будет закладываться текущее состояние

# Состояния персонажа, в которые он переходит
var character_states = {
	State.IDLE: state_idle,
	State.DEATH: state_death,
	State.HIT: state_hit,
}

func _ready():
	GameStats.player_leveled_up.connect(_on_level_up) 
	time_damage.one_shot = false # повторный тик таймера
	time_damage.autostart = false  # не запускать сразу
	#time_damage.timeout.connect(_on_damage_timer_timeout) # подписка на таймаут

func _process(_delta: float) -> void: #вызывается каждый кадр
	character_states[current_state].call()
	if death and current_state!=State.DEATH: 
		current_state = State.DEATH
		

func state_idle():
	var direction = movement_vector().normalized() #нормализируем выходные данные, чтобы не получилось больше 0, чтобы персонаж не бежал быстрее по диагонали
	velocity = max_speed * direction #умножаем переменную на скорость, чтобы задать движение
	if current_state == State.IDLE:
		if velocity != Vector2(0,0): #поворот анимации персонажа
			anim_player.play("Run")
			if direction.x != 0:
				attack_facing_direction = sign(direction.x) # Только если движется по X
				anim_sprite.scale.x = -1 if direction.x < 0 else 1
			move_and_slide() #применяем физику
		else:
			anim_player.play("Idle")
	if direction != Vector2.ZERO:
		last_movement_direction = direction # сохраняем направление, если двигаемся

func movement_vector():
	var movement_x = Input.get_action_strength("right") - Input.get_action_strength("left")
	var movement_y = Input.get_action_strength("down") - Input.get_action_strength("up")
	return Vector2(movement_x,movement_y)

#состояние смерти
func state_death():
	velocity = Vector2(0,0)
	queue_free()

#Состояние получения урона
func state_hit():
	if is_processing_hit:
		return
	
	is_processing_hit = true #Переменная от спама урона в процессе получения удара
	var current_health_local = GameStats.stats_player["current_health"]
	#print("Текущее здоровье ", current_health_local)
	current_health_local -= amount #Получаем урон
	#print("Игрок получил урон. Здоровье:", current_health_local) 
	GameStats.stats_player["current_health"] = current_health_local #Передаю текущее здоровье в GameStats
	
	if current_health_local > 0:
		anim_player.play("Hit")
		await anim_player.animation_finished #Ждем окончания анимации удара
		is_processing_hit = false
		current_state = State.IDLE
	else :
		death = true
		current_state = State.DEATH

#Сигнал входа HitBox врага в HurtBox персонажа
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.name == "HitBox" and area.get_parent().is_in_group("Enemies"):
		# Присваеваем врага переменной enemy
		var enemy = area.get_parent()
		# Берем из переменной врага переменную с уроном
		amount = enemy.damage
		current_state = State.HIT #Переходим в состояние получения урона
		
		if enemies_in_hurtbox.has(enemy) == false: # нет в списке?
			enemies_in_hurtbox.append(enemy) # добавляем врага
			
		if time_damage.is_stopped(): # если таймер стоит
			time_damage.start() # запускаем тики урона

#Функция для удаления врагов из массива, когда они выходят из зоны
func _on_hurt_box_area_exited(area: Area2D) -> void:
	# удалить врага при выходе
	if area.name == "HitBox" and area.get_parent().is_in_group("Enemies"): # проверка врага
		var enemy = area.get_parent() # получаем узел врага
		enemies_in_hurtbox.erase(enemy) # убираем из списка
		if enemies_in_hurtbox.is_empty(): # никого внутри?
			if not time_damage.is_stopped(): # если тикает
				time_damage.stop() # останавливаем таймер

#Находит врагов в радиусе
func _on_enemy_scan_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"): #если это враг
		enemies_in_EnemyScanArea.append(body) # добавить в список

#Определяет ближайшего врага
func on_request_target_enemy(ray: Node2D) -> void:
	if enemies_in_EnemyScanArea.is_empty():
		return
	
	var closest_enemy: Node2D = null # переменная под ближайшего врага
	var closest_distance := INF # бесконечное расстояние для начального сравнения
	
	# Перебираем всех врагов в списке
	for enemy in enemies_in_EnemyScanArea:
		if not is_instance_valid(enemy): # если враг был удалён
			continue
			
		var distance = global_position.distance_to(enemy.global_position) # расстояние до врага
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
			
	# После цикла проверяем, найден ли враг
	if closest_enemy != null:
		if ray.has_method("set_target"): # проверяем, есть ли у луча нужный метод
			ray.set_target(closest_enemy) # вызываем метод луча, передаём врага

#Функция сбора предметов
func _on_collectible_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("Collectibles"): # если это предмет
		if area.has_method("start_following"): # у него есть метод притягивания
			area.start_following(self) # передаём ссылку на себя

#Функция сохранения последнего движения направления игрока
func get_last_movement_direction() -> Vector2:
	return last_movement_direction # возвращает сохранённое направление

#Функция получения урона, если в HurtBox есть кто-то из врагов
func _on_damage_timer_timeout() -> void:
	# тик повторного урона
	if death: # не бьём мёртвого
		return # выходим
	
	# Чистим невалидных врагов
	enemies_in_hurtbox = enemies_in_hurtbox.filter( # фильтруем список
		func(e): return is_instance_valid(e) # живой узел?
	)
	
	if enemies_in_hurtbox.is_empty(): # никого внутри
		if not time_damage.is_stopped(): # таймер работал?
			time_damage.stop() # останавливаем
		return # выходим
		
	if is_processing_hit: # уже получаем удар?
		return # пропускаем тик
	
	# Выбираем самый опасный урон
	var max_damage := 0 # локальная переменная
	for e in enemies_in_hurtbox: # пробегаем врагов
		if "damage" in e: # есть поле damage?
			max_damage = max(max_damage, int(e.damage)) # берём максимум
	
	if max_damage <= 0: # безопасная проверка
		return # урона нет
	
	amount = max_damage # записываем урон
	current_state = State.HIT # триггерим состояние

#Функция повышения уровня, включает FX и экран прокачки
func _on_level_up(): #этот метод вызывается при сигнале из GameStats, там начало, при прокачке
	Level_up_fx.restart()
