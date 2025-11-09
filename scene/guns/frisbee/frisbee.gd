extends Node2D # узел фрисби #

@onready var frisbee_area = $Area2D # берём область удара
@onready var lifetime_timer = $Timer # берём таймер жизни 

var damage = GameStats.stats_player["attack"]["frisbee"]["damage"] # урон 
var speed = GameStats.stats_player["attack"]["frisbee"]["speed"] # скорость 
var size = GameStats.stats_player["attack"]["frisbee"]["size"] # размер 
var hits = GameStats.stats_player["attack"]["frisbee"]["hits"] # пробитий до исчезновения 

var _dir: Vector2 = Vector2.RIGHT # внутреннее направление 
var _owner: Node2D = null # ссылка на игрока 

func setup(direction: Vector2, owner: Node2D) -> void: # инициализация 
	_dir = direction.normalized() # сохраняем нормализованное направление 
	_owner = owner # сохраняем ссылку на игрока 
	scale = Vector2.ONE * clamp(size, 0.25, 4.0) # масштаб узла под размер 
	if lifetime_timer: lifetime_timer.start() # запускаем таймер жизни 

func _ready() -> void: # при входе в сцену
	if frisbee_area: frisbee_area.area_entered.connect(_on_frisbee_area_entered) # подписываемся на вход в нашу Area2D
	if lifetime_timer: lifetime_timer.one_shot = true # одно срабатывание таймера


func _physics_process(delta: float) -> void: # кадр физики
	if _dir == Vector2.ZERO: return # если направление ноль, ничего не делаем
	position += _dir * speed * delta # двигаем фрисби
	rotation = _dir.angle() # поворачиваем по направлению

func _on_frisbee_area_entered(area: Area2D) -> void: # пересечение
	if area.name == "HitBox" and area.get_parent().is_in_group("Enemies"): # это враг?
		var enemy = area.get_parent() # берём врага
		if enemy.has_method("take_damage_from_player"): enemy.take_damage_from_player(damage) # наносим урон (вариант 1)
		elif enemy.has_method("take_damage"): enemy.take_damage(damage) # наносим урон (вариант 2)
		elif enemy.has_method("apply_damage"): enemy.apply_damage(damage) # наносим урон (вариант 3)
		hits -= 1 # уменьшаем остаток
		if hits <= 0: queue_free() # удаляем фрисби если пробития кончились

func _on_timer_timeout() -> void: # окончание жизни
	queue_free() # удаляемся
