extends Node

signal player_leveled_up # глобальный сигнал прокачки

#Харакетеристики собираемых предметов
var stats_collectibles = {
	"max_speed" : 300, #скорость предмета
	"xp_up_low" : 20, #кол-во прибавляемого опыта слабой версией
}

#Характеристики персонажа
var stats_player = {
	"level" : 1, #уровень персонажа, поднимается при поднятии опыта
	"current_xp" : 0, #опыт персонажа, прокачивается при убийстве монстров
	"xp_to_next_level" : 100, #опыт персонажа, прокачивается при убийстве монстров
	"max_speed" : 200, #скорость персонажа
	"max_health" : 100, #здоровье персонажа
	"current_health" : 100, #текущее здоровье персонажа
	"current_armor" : 0, #текущая броня персонажа
	"max_armor" : 50, #броня, которая поглащает часть урона, будет вычитаться из наносимого урона персонажу 
	"max_radius_collectible" : 7, #радиус сбора предметов
	"attack" : {
		"bears_paw":{
			"activated" : true, #атака лапой активация
			"damage" : 50, #атака лапой урон
			"speed_cast" : 1, #атака лапой скорость каста
			"stage" : 0, #атака лапой уровень прокачки (привязать её к анимации лапы, разные уровни - разные анимации)
			"time_wait" : 2.2, #время между ударами
		},
		"spotlight_ray":{
			"activated" :false, #луч активация
			"damage" : 100, #луч урон
			"speed_cast" : 1, #луч скорость каста
			"stage" : 0, #луч уровень прокачки (привязать её к анимации лапы, разные уровни - разные анимации)
			"time_wait" : 4.4, #время между ударами
		},
		"grinder_star":{
			"activated" : false, #звезда активация
			"damage" : 25, #звезда урон
			"speed_cast" : 8, #звезда скорость вращения
			"radius" : 50, #звезда радиус орбиты
			"count" : 3, #звезда кол-во элементов
			"size": 1, #звезда размер элементов
			"stage" : 0, #звезда уровень прокачки (привязать её к анимации лапы, разные уровни - разные анимации)
			"time_wait" : 5.3, #время между ударами
		},
		"thunderweb":{
			"activated" : false, #молния активация
			"damage" : 50, #молния урон
			"length_segment" : 1.5, #молния длина сегмента молнии
			"first_count_branch" : 1, #молния кол-во первых веток 3
			"count_branch" : 2, #молния кол-во первых веток 2
			"count_steps" : 4, #молния, кол-во ступеней молнии 5
			"angle_branch": 0.3, #угол между ветками, относительно нормали нарпавления молнии
			"stage" : 0, #молния уровень прокачки (привязать её к анимации лапы, разные уровни - разные анимации) !этого параметра пока что нет
			"time_wait" : 4.6, #время между ударами
		},
		"blade_yoyo":{
			"activated" : false, #йо-йо активация
			"damage" : 100, #йо-йо урон
			"speed_high_move" : 50, #йо-йо скорость подъем элемента от персонажа
			"speed_radial_move" : 3, #йо-йо скорость радиального полета элемента
			"count" : 1, #йо-йо, кол-во элементов
			"size" : 0.6, #йо-йо, размер элементов
			"stage" : 0, #йо-йо уровень прокачки (привязать её к анимации лапы, разные уровни - разные анимации) !этого параметра пока что нет
			"time_wait" : 2.5, #время между ударами
		},
		"groundwave":{
			"activated" : false, #удар о землю, активация
			"damage" : 10, #удар о землю, урон
			"knockback_force" : 400, #удар о землю,сила отбрасывания
			"stage" : 0, #удар о землю, уровень прокачки (привязать её к анимации лапы, разные уровни - разные анимации) !этого параметра пока что нет
			"time_wait" : 4, #время между ударами
		},
		"frisbee":{
			"activated" : false, #фрисби активация
			"damage" : 50, #фрисби урон
			"count" : 1, #фрисби, кол-во элементов
			"speed" : 600, #фрисби, скорость полета
			"size" : 1.2, #фрисби, размер элементов
			"hits" : 1, #фрисби, кол-во столкновений при полете
			"stage" : 0, #фрисби уровень прокачки (привязать её к анимации лапы, разные уровни - разные анимации) !этого параметра пока что нет
			"time_wait" : 1.8, #время между ударами
		},
	}
}

#Характеристики моба глаз, могут изменяться в зависимости от сложности в дальнейшем
var stats_eye_ball = {
	"max_speed" = 80,
	"max_health" = 100,
	"damage" = 0 # !!!!!!!!!!!!!!!ВРЕМЕННО ИЗМЕНИЛ, ВРАГИ ТЕПЕРЬ НЕ НАНОСЯТ УРОН
}

#Характеристики спаунера мобов
var enemy_spawner = {
	"max_count_mobs" = 200,
	"count_mobs_in_screen" = 0,
	"current_spawn_interval" = 3.0,
	"game_time" = 0.0,
	"max_game_time" = 2400.0
}

var final_game_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass

func check_level_up():
	var xp = stats_player["current_xp"]
	var xp_needed = stats_player["xp_to_next_level"]
	
	if xp >= xp_needed:
		stats_player["level"] += 1
		stats_player["current_xp"] -= xp_needed # вычитаем потраченный опыт
		stats_player["xp_to_next_level"] = round(calculate_xp_to_next(stats_player["level"])) #round(xp_needed * 1.8) # увеличиваем порог
		
		player_leveled_up.emit() #отправляем сигнал игроку и всех, кто подписан на сигнал, новый синтаксис передачи сигнала

func calculate_xp_to_next(level: int) -> int: #функция расчета повышения уровня
	return int(50 * pow(level, 1.5))
