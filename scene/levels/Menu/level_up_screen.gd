extends CanvasLayer # экран прокачки

@export var upgrade_card_scene: PackedScene # префаб карточки
@onready var box_container: Node = $BoxContainer # контейнер для карточек

signal choice_selected(choice: Dictionary) # сигнал о выборе карточки

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # этот UI работает на паузе
	visible = false # по умолчанию скрыт

func show_choices(choices: Array) -> void: # создать и показать карточки
	if upgrade_card_scene == null:
		print("[LevelUpScreen] upgrade_card_scene не задан — назначь префаб в инспекторе") # предупреждение
		return # выходим
	visible = true # показываем экран
	for child in box_container.get_children(): child.queue_free() # чистим старые карточки
	for choice_dict in choices: # создаём карточки по данным
		var card := upgrade_card_scene.instantiate() # инстансим карточку
		box_container.add_child(card) # добавляем в контейнер
		if card.has_method("setup_from_choice"):
			card.setup_from_choice(choice_dict) # заполняем UI
			
		if card.has_signal("confirm"): 
			card.confirm.connect(_on_card_confirm) # ловим нажатие

func _on_card_confirm(choice: Dictionary) -> void: # нажали ОК на карточке
	choice_selected.emit(choice) # пробрасываем выбор наверх

func hide_screen() -> void: # спрятать экран
	visible = false # скрываем слой
	for child in box_container.get_children(): child.queue_free() # убираем карточки
