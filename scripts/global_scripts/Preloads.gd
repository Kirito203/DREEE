extends CanvasLayer # слой интерфейса

const FX_LEVEL_UP := preload("res://scene/mobs/FX_material_mobs/player_level_up.tres") # грузим заранее
const FX_KILL := preload("res://scene/mobs/FX_material_mobs/eye_ball.tres") # грузим заранее

var fx_mats := [FX_LEVEL_UP, FX_KILL] # список материалов

var warmed := false # флаг прогрева

func _ready() -> void: # вход в дерево
	# делаем прогрев партиклов
	await _warm_particles() # ждём завершения
	warmed = true # отмечаем готовность

func _warm_particles() -> void: # функция прогрева
	for mat in fx_mats: # перебираем материалы
		if mat == null: # проверяем нулл
			push_warning("Материал не найден") # предупреждаем
			continue # переходим дальше
		if not (mat is ParticleProcessMaterial): # проверяем тип
			push_warning("Это не материал партиклов") # предупреждаем
			continue # переходим дальше

		var p := GPUParticles2D.new() # создаём партиклы
		p.process_material = mat # назначаем материал
		p.one_shot = false # циклический режим
		p.preprocess = 2.0 # прокрутить 2 сек
		p.emitting = true # запустить эмиссию
		p.modulate = Color(1,1,1,0) # полностью прозрачный
		p.visible = false # не рисовать ноду
		p.amount = max(8, p.amount) # минимум 8 штук
		add_child(p) # добавляем в сцену

		await get_tree().process_frame # ждём кадр
		await get_tree().process_frame # ждём ещё кадр

		p.emitting = false # останавливаем эмиссию
		p.preprocess = 0.0 # сбрасываем прогрев
		# можно не удалять ноду
		# оставить как кэш
		# если хочешь удалить:
		# p.queue_free()


#extends CanvasLayer
#
#var level_up_particles = "res://scene/mobs/FX_material_mobs/player_level_up.tres"
#var kill_mob_particles = "res://scene/mobs/FX_material_mobs/eye_ball.tres"
#
#var fx = [ #сюда добавляются новые партиклы, которые используются в игре
	#level_up_particles,
	#kill_mob_particles,
#]
#
#var frames = 0
#var loaded = false
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void: 
	#for fx in fx: #подгружаются все партиклы из списка
		#var particles_instance = GPUParticles2D.new()
		#particles_instance.set_process_material(fx)
		#particles_instance.set_one_shot(true) #не уверен, что эта строка нужна
		#particles_instance.set_modulate(Color(1,1,1,0)) #не уверен, что эта строка нужна
		#particles_instance.set_emitting(true) #не уверен, что эта строка нужна
		#self.add_child(particles_instance)
#
#
#func _physics_process(delta: float) -> void:
	#if frames >=3:
		#set_physics_process(false) #ставим, чтобы прекратить подгрузку
		#loaded = true
	#frames += 1
