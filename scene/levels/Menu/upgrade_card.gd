extends Panel # карточка

signal confirm(choice_data: Dictionary) # сигнал подтверждения

var card_choice_data: Dictionary = {} # данные конкретной карточки

func setup_from_choice(choice_dictionary: Dictionary) -> void: # заполнение карточки
	card_choice_data = choice_dictionary # сохраняем переданный словарь
	$VBoxContainer/SkillName_001.text = choice_dictionary.get("title","") # заголовок
	$VBoxContainer/SkillDescription_001.text = choice_dictionary.get("description","") # описание
	$VBoxContainer/Button_001.pressed.connect(on_button_pressed) # подключаем к кнопке

func on_button_pressed() -> void: # клик по кнопке
	confirm.emit(card_choice_data) # отправляем данные карточки наружу
