extends Node2D

@export var eye_ball_folder: NodePath

@export var mob_eye_ball_01 : PackedScene = preload("res://scene/mobs/eye_ball/eye_ball.tscn") #предзагрузка файла моба
var eye_ball_pool_size : int = 20 # кол-во заготовленных мобов
var eye_ball_pool: Array = [] #массив свободных мобов
var eye_ball_pool_done = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if eye_ball_pool_done == true:
		pass
	else:
		var folder = get_node(eye_ball_folder) #Переводим папку в папку, чтобы код нашел путь
		for i in eye_ball_pool_size: #Создаем заранее всех мобов
			var mob = mob_eye_ball_01.instantiate()
			mob.set_process(false)
			mob.set_physics_process(false)
			mob.show() 
			mob.hide() #отключаем видимость у моба
			folder.add_child(mob) #создаем моба, пока держим внутри пулла
			eye_ball_pool.append(mob) #кладем в список
		var eye_ball_pool_done = true

func get_mob():
	if eye_ball_pool.is_empty(): #проверка, если архив пустой, ничего не передаем
		return null
	var mob = eye_ball_pool.pop_back()
	mob.visible = true
	return mob

func return_pool(mob: CharacterBody2D):
	eye_ball_pool.append(mob)
	mob.set_process(false)
	mob.set_physics_process(false)
	mob.hide()
