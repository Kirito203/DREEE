extends Node2D

@export var eye_ball_folder: NodePath
@export var mob_eye_ball_01: PackedScene = preload("res://scene/mobs/eye_ball/eye_ball.tscn")

var eye_ball_pool_size: int = 20
var eye_ball_pool: Array[CharacterBody2D] = []
var eye_ball_pool_done: bool = false

func _ready() -> void:
	_create_pool_deferred()

func _create_pool_deferred() -> void:
	if eye_ball_pool_done:
		return
	var folder: Node = get_node(eye_ball_folder) as Node
	var batch_size: int = 10
	var created: int = 0
	while created < eye_ball_pool_size:
		var to_create: int = min(batch_size, eye_ball_pool_size - created)
		for i in range(to_create):
			var mob: CharacterBody2D = mob_eye_ball_01.instantiate() as CharacterBody2D
			mob.set_process(false)
			mob.set_physics_process(false)
			mob.hide()
			folder.call_deferred("add_child", mob)
			eye_ball_pool.append(mob)
		created += to_create
		await get_tree().process_frame
	eye_ball_pool_done = true

func get_mob() -> CharacterBody2D:
	if eye_ball_pool.is_empty():
		return _expand_and_get()
	var mob: CharacterBody2D = eye_ball_pool.pop_back() as CharacterBody2D
	_activate_mob(mob)
	return mob

func return_pool(mob: CharacterBody2D) -> void:
	_deactivate_mob(mob)
	eye_ball_pool.append(mob)

func _activate_mob(mob: CharacterBody2D) -> void:
	mob.visible = true
	mob.set_process(true)
	mob.set_physics_process(true)

func _deactivate_mob(mob: CharacterBody2D) -> void:
	mob.set_process(false)
	mob.set_physics_process(false)
	mob.hide()
	mob.global_position = Vector2.ZERO

func _expand_and_get() -> CharacterBody2D:
	var folder: Node = get_node(eye_ball_folder) as Node
	var mob: CharacterBody2D = mob_eye_ball_01.instantiate() as CharacterBody2D
	mob.hide()
	folder.add_child(mob)
	_activate_mob(mob)
	return mob
