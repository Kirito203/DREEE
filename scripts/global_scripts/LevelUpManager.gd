extends Node # менеджер прокачки

signal show_card # запасной сигнал
signal check_attack_activated # сигнал для AttackController после применения апгрейда

var level_up_screen: CanvasLayer = null # ссылка на экран прокачки

var spend_up: Dictionary = { # стимуляторы
	"heal_100": { "title": "Восполнить здоровье 100", "description": "Восполняет здоровье на 100 ед", 
	"effects": [
		{ "path": "stats_player.current_health", "effect": "add", "value": 100 }
	]
	},
	"heal_200": { "title": "Восполнить здоровье 200", "description": "Восполняет здоровье на 200 ед", 
	"effects": [
		{ "path": "stats_player.current_health", "effect": "add", "value": 200 }
	]
	},
} # словарь стимов

var player_stats_up: Dictionary = { # словарь апгрейдов характеристик
	"max_health": [
		{
			"level": 1, "title": "Максимум здоровья 1", "description": "Увеличивает максимальное здоровье персонажа до 120 ед",
			"effects": [
				{ "path": "stats_player.max_health", "effect": "set", "value": 120 },
			]
		},
		{
			"level": 2, "title": "Максимум здоровья 2", "description": "Увеличивает максимальное здоровье персонажа до 140 ед",
			"effects": [
				{ "path": "stats_player.max_health", "effect": "set", "value": 140 },
			]
		},
		{
			"level": 3, "title": "Максимум здоровья 2", "description": "Увеличивает максимальное здоровье персонажа до 160 ед",
			"effects": [
				{ "path": "stats_player.max_health", "effect": "set", "value": 160 },
			]
		},
	],
	"max_speed": [
		{
			"level": 1, "title": "Максимальная скорость 1", "description": "Увеличивает максимальную скорость персонажа на 10%",
			"effects": [
				{ "path": "stats_player.max_speed", "effect": "set", "value": 220 },
			]
		},
		{
			"level": 2, "title": "Максимальная скорость 2", "description": "Увеличивает максимальную скорость персонажа на 10%",
			"effects": [
				{ "path": "stats_player.max_speed", "effect": "set", "value": 242 },
			]
		},
		{
			"level": 3, "title": "Максимальная скорость 3", "description": "Увеличивает максимальную скорость персонажа на 10%",
			"effects": [
				{ "path": "stats_player.max_speed", "effect": "set", "value": 266 },
			]
		},
	]
}

var player_attack_default: Dictionary = { # дефолтные атаки
	"bears_paw": [
		{
			"level": 2, "title": "Размашистый удар 2", "description": "Размашистый удар наносит 75 единиц урона всем врагам в радиусе действия атаки.",
			"effects": [
				{ "path": "stats_player.attack.bears_paw.damage", "effect": "set", "value": 75 },
			]
		},
		{
			"level": 3, "title": "Размашистый удар 2", "description": "Увеличивает урон размашистого удара до 100 ед",
			"effects": [
				{ "path": "stats_player.attack.bears_paw.damage", "effect": "set", "value": 100 },
			]
		},
		{
			"level": 4, "title": "Размашистый удар 3", "description": "Увеличивает урон у размашистого удара до 125 ед",
			"effects": [
				{ "path": "stats_player.attack.bears_paw.damage", "effect": "set", "value": 125 },
			]
		},
	],
}

var player_attack_one_up: Dictionary = { # апгрейды 1-го рида
	"thunderweb": [
		{
			"level": 1, "title": "Молния 1", "description": "Активация атаки молнией. Молния бьет в направлении движения игрока и распространяется конусом. Наносит 25 ед урона врагам.",
			"effects": [
				{ "path": "stats_player.attack.thunderweb.activated", "effect": "set", "value": true },
			]
		},
		{
			"level": 2, "title": "Молния 2", "description": "Увеличивает урон от молнии до 50 ед.",
			"effects": [
				{ "path": "stats_player.attack.thunderweb.damage", "effect": "set", "value": 50 },
			]
		},
		{
			"level": 3, "title": "Молния 3", "description": "Добавляет ещё 1 ветку молнии, делая удар шире. Уменьшает время между атаками на 25%",
			"effects": [
				{ "path": "stats_player.attack.thunderweb.first_count_branch", "effect": "set", "value": 2 },
				{ "path": "stats_player.attack.thunderweb.time_wait", "effect": "set", "value": 3.2 },
			]
		},
		{
			"level": 4, "title": "Молния 4", "description": "Увеличивает урон от молнии до 75 ед.",
			"effects": [
				{ "path": "stats_player.attack.thunderweb.damage", "effect": "set", "value": 75 },
			]
		},
		{
			"level": 5, "title": "Молния 5", "description": "Делает распространение молнии дальше и шире в конце. Уменьшает время между атаками на 25%",
			"effects": [
				{ "path": "stats_player.attack.thunderweb.count_steps", "effect": "set", "value": 5 },
				{ "path": "stats_player.attack.thunderweb.time_wait", "effect": "set", "value": 2.7 },
			]
		},
	],
	"frisbee": [
		{
			"level": 1, "title": "Фрисби 1", "description": "Активирует фрисби. Фрисби летит по прямой траектории в направлении движения игрока. Наносит 50 единиц урона. При попадании по противнику - исчезает",
			"effects": [
				{ "path": "stats_player.attack.frisbee.activated", "effect": "set", "value": true },
			]
		},
		{
			"level": 2, "title": "Фрисби 2. Урон.", "description": "Урон у фрисби увеличивается до 100 ед",
			"effects": [
				{ "path": "stats_player.attack.frisbee.damage", "effect": "set", "value": 100 },
			]
		},
		{
			"level": 3, "title": "Фрисби 3. Урон.", "description": "Урон у фрисби увеличивается до 150 ед и пролетает сквозь одного врага",
			"effects": [
				{ "path": "stats_player.attack.frisbee.damage", "effect": "set", "value": 150 },
				{ "path": "stats_player.attack.frisbee.hits", "effect": "set", "value": 2 },
			]
		},
	]
}

var player_attack_two_up: Dictionary = { # апгрейды 2-го рида
	"grinder_star": [
		{
			"level": 1, "title": "Звезды 1", "description": "Появляется 3 звезды, вращающиеся вокруг игрока определенное время, после чего исчезают. Звезды наносят урон всем попадающимся противникам 25 ед.",
			"effects": [
				{ "path": "stats_player.attack.grinder_star.activated", "effect": "set", "value": true },
			]
		},
		{
			"level": 2, "title": "Звезды 2. Урон.", "description": "Урон от звезд увеличивается до 50 ед",
			"effects": [
				{ "path": "stats_player.attack.grinder_star.damage", "effect": "set", "value": 50 },
			]
		},
	],
	"blade_yoyo": [
		{
			"level": 1, "title": "Йо-йо 1", "description": "Появляется йо-йо, снаряд летит по спирали вокруг игрока какое-то время, если снаряд задевает противника - наносится 100 ед урона.",
			"effects": [
				{ "path": "stats_player.attack.blade_yoyo.activated", "effect": "set", "value": true },
			]
		},
		{
			"level": 2, "title": "Йо-йо 2. Урон и кол-во.", "description": "Йо-йо наносит 150 ед урона и появляется ещё 1 снаряд",
			"effects": [
				{ "path": "stats_player.attack.blade_yoyo.damage", "effect": "set", "value": 150 },
				{ "path": "stats_player.attack.blade_yoyo.count", "effect": "set", "value": 2 },
			]
		},
	],
}

var player_attack_three_up: Dictionary = { # апгрейды 2-го рида
	"groundwave": [
		{
			"level": 1, "title": "Ударная волна 1", "description": "Персонаж бьет о землю вызывая ударную волну. Отбрасывает противников и наносит 25 ед.",
			"effects": [
				{ "path": "stats_player.attack.groundwave.activated", "effect": "set", "value": true },
			]
		},
		{
			"level": 2, "title": "Ударная волна 2", "description": "Усиливает силу отбрасывания противников на 30%",
			"effects": [
				{ "path": "stats_player.attack.groundwave.knockback_force", "effect": "set", "value": 520 },
			]
		},
		{
			"level": 3, "title": "Ударная волна 3", "description": "Усиливает силу отбрасывания противников ещё на 30%",
			"effects": [
				{ "path": "stats_player.attack.groundwave.knockback_force", "effect": "set", "value": 675 },
			]
		},
		{
			"level": 4, "title": "Ударная волна 4", "description": "Увеличивает скорость появления атаки на 25%",
			"effects": [
				{ "path": "stats_player.attack.groundwave.time_wait", "effect": "set", "value": 3 },
			]
		},
		{
			"level": 5, "title": "Ударная волна 4", "description": "Увеличивает скорость появления атаки на 20%",
			"effects": [
				{ "path": "stats_player.attack.groundwave.time_wait", "effect": "set", "value": 2.5 },
			]
		},
		{
			"level": 6, "title": "Ударная волна 4", "description": "Увеличивает скорость появления атаки ещё на 20%",
			"effects": [
				{ "path": "stats_player.attack.groundwave.time_wait", "effect": "set", "value": 2 },
			]
		},
	],
}


var MAX_PASSIVES_OWNED: int = 3 # максимум пассивок, которые можно взять за сессию
var RIDS_ENABLED: int = 3 # сколько ридов атак используется (1..6)

var passive_level_by_id: Dictionary = {} # прогресс пассивок по id
var owned_passive_ids: Array[String] = [] # какие пассивки уже брали
var chosen_attack_id_by_rid: Dictionary = {} # выбранная атака в каждом риде
var attack_level_by_id: Dictionary = {} # прогресс атак по id (включая дефолт)
var unlocked_attack_rids: Array[String] = [] # список открытых ридов
var default_attack_id: String = "" # id дефолтной атаки


func _ready() -> void: # инициализация
	randomize() # включаем RNG
	_detect_default_attack_id() # определяем дефолтную атаку
	GameStats.player_leveled_up.connect(on_player_leveled_up) # подписываемся на ап уровня
	_find_and_hook_level_up_screen() # ищем UI и вешаем сигнал

func _detect_default_attack_id() -> void: # поиск активной дефолтной атаки
	default_attack_id = "" # сбрасываем на всякий случай
	if GameStats.stats_player.has("attack"): # есть блок атак
		var atk := GameStats.stats_player["attack"] as Dictionary # берём словарь атак
		for id in player_attack_default.keys(): # по ключам дефолта
			if atk.has(id) and (atk[id] as Dictionary).get("activated", false): # если дефолт активирован
				default_attack_id = String(id) # сохраняем id дефолта
				return # выходим сразу
	# без активации дефолта не выбираем первый попавшийся # важная правка

func _find_and_hook_level_up_screen() -> void: # поиск и подключение UI
	level_up_screen = get_tree().root.find_child("LevelUpScreen", true, false) as CanvasLayer # ищем узел
	if level_up_screen: level_up_screen.process_mode = Node.PROCESS_MODE_ALWAYS # чтобы работал на паузе
	if level_up_screen and level_up_screen.has_signal("choice_selected") and not level_up_screen.choice_selected.is_connected(on_card_choice_selected): # проверка
		level_up_screen.choice_selected.connect(on_card_choice_selected) # подключаем колбэк

func on_player_leveled_up() -> void: # событие апа уровня
	await get_tree().create_timer(0.3).timeout # небольшая задержка
	get_tree().paused = true # ставим игру на паузу
	if not level_up_screen: _find_and_hook_level_up_screen() # повторный поиск
	if level_up_screen: # если экран найден
		var cards: Array = _build_choices() # собираем карточки
		level_up_screen.show_choices(cards) # показываем
	else:
		print("[LevelUpManager] Нет LevelUpScreen — карточки не показать") # лог

func _build_choices() -> Array: # финальная сборка трёх карт
	if _is_everything_maxed(): # если совсем нет вариантов
		return _pick_spend_cards_by_stock() # показываем стимы
	var result: Array = [] # итоговый список карт
	var passive_candidates: Array = _build_passive_candidates() # собираем пассивки
	var attack_pool: Array = _collect_attack_cards(3) # собираем атаки
	var want_attacks: int = 2 # минимум 2 атаки
	if attack_pool.size() >= 3 and randf() < 0.5: want_attacks = 3 # иногда 3 атаки
	if attack_pool.size() < 2: want_attacks = attack_pool.size() # если атак мало
	attack_pool.shuffle() # перемешиваем
	for i in range(min(want_attacks, attack_pool.size())): # добавляем атаки
		result.append(attack_pool[i]) # добавляем
	if result.size() < 3: # если осталось место
		passive_candidates.shuffle() # перемешиваем
		if result.size() <= 1 and attack_pool.size() > result.size(): # можно добрать атаки
			var need_more_attacks: int = min(3 - result.size(), attack_pool.size() - result.size()) # сколько добирать
			for j in range(need_more_attacks): # добавляем
				if result.size() >= 3: break # выходим
				result.append(attack_pool[result.size()]) # добираем атаками
		while result.size() < 3 and passive_candidates.size() > 0: # добираем пассивками
			result.append(passive_candidates.pop_back()) # добавляем
	while result.size() < 3: # крайний случай
		var extra_attack: Dictionary = _pick_any_extra_attack_card(result) # пробуем атаку
		if extra_attack.size() > 0: result.append(extra_attack) # добавляем атаку
		elif passive_candidates.size() > 0: result.append(passive_candidates.pop_back()) # добавляем пассивку
		else: break # нечего добавлять
	return result # возвращаем карты

func _build_passive_candidates() -> Array: # собираем список пассивок для показа
	var candidates: Array = [] # сюда
	for passive_id in player_stats_up.keys(): # по веткам
		var levels: Array = player_stats_up[passive_id] as Array # уровни
		var cur_level: int = int(passive_level_by_id.get(passive_id, 0)) # текущий
		var max_level: int = levels.size() # максимум
		if cur_level >= max_level: continue # на максимуме
		var already_owned: bool = owned_passive_ids.has(passive_id) # уже брали?
		if already_owned or owned_passive_ids.size() < MAX_PASSIVES_OWNED: # можно предлагать
			var next_dict: Dictionary = levels[cur_level] as Dictionary # следующий уровень
			candidates.append({ "type": "passive", "id": passive_id, "next_level": cur_level + 1, "max_level": max_level, "title": next_dict.get("title", passive_id), "description": next_dict.get("description", "") }) # карта
	return candidates # возвращаем

func _collect_attack_cards(max_total: int) -> Array: # собираем пул атак с учётом правил
	var pool: Array = [] # итоговый пул
	var unopened: Array[String] = [] # список неоткрытых ридов
	if RIDS_ENABLED >= 1 and not unlocked_attack_rids.has("rid_1"): unopened.append("rid_1") # rid_1
	if RIDS_ENABLED >= 2 and not unlocked_attack_rids.has("rid_2"): unopened.append("rid_2") # rid_2
	if RIDS_ENABLED >= 3 and not unlocked_attack_rids.has("rid_3"): unopened.append("rid_3") # rid_3
	
	unopened.shuffle() # перемешиваем
	if unopened.size() > 0: # если есть закрытые риды
		var base_rid: String = unopened[0] # берём первый
		var base_dict: Dictionary = _rid_dict_by_name(base_rid) # словарь атак
		var base_candidates: Array = _start_candidates_for_rid(base_rid, base_dict, max_total) # старты
		for c in base_candidates: # переносим
			if pool.size() >= max_total: break # лимит
			pool.append(c) # добавляем
		for i in range(1, unopened.size()): # остальные риды
			if pool.size() >= max_total: break # лимит
			var rid_name2: String = unopened[i] # имя
			var dict2: Dictionary = _rid_dict_by_name(rid_name2) # словарь
			var more: Array = _start_candidates_for_rid(rid_name2, dict2, max_total - pool.size()) # старты
			for c2 in more: # переносим
				if pool.size() >= max_total: break # лимит
				var dup := false # флаг дубля
				for ex in pool:
					if str(ex.get("rid_name","")) == str(c2.get("rid_name","")) and str(ex.get("attack_id","")) == str(c2.get("attack_id","")): dup = true; break # дубль
				if not dup: pool.append(c2) # добавляем
	if pool.size() < max_total: # если места ещё есть
		var upgrades: Array = _build_attack_candidates_distinct_rids(max_total - pool.size()) # апы
		for u in upgrades: # переносим
			if pool.size() >= max_total: break # лимит
			var dup2 := false # флаг
			for ex2 in pool:
				if str(ex2.get("rid_name","")) == str(u.get("rid_name","")) and str(ex2.get("attack_id","")) == str(u.get("attack_id","")): dup2 = true; break # дубль
			if not dup2: pool.append(u) # добавляем
	if pool.size() < max_total: # если ещё есть слот
		var def_card: Dictionary = _build_default_attack_candidate() # дефолт
		if def_card.size() > 0 and randf() < 0.6: # 60% шанса
			pool.append(def_card) # добавляем
	pool.shuffle() # перемешиваем
	return pool # отдаём

func _start_candidates_for_rid(rid_name: String, rid_dict: Dictionary, count: int) -> Array: # стартовые карты из рида
	var attack_ids: Array = rid_dict.keys() # все атаки рида
	if attack_ids.is_empty(): return [] # пусто
	attack_ids.shuffle() # перемешиваем
	var out: Array = [] # сюда
	for i in range(min(count, attack_ids.size())): # ограничение
		var attack_id: String = str(attack_ids[i]) # id атаки
		var levels: Array = rid_dict[attack_id] as Array # уровни
		if levels.is_empty(): continue # защита
		var lvl1: Dictionary = levels[0] as Dictionary # первый уровень
		out.append({ "type": "attack", "rid_name": rid_name, "attack_id": attack_id, "next_level": 1, "max_level": levels.size(), "title": lvl1.get("title", attack_id), "description": lvl1.get("description", "") }) # карта
	return out # отдаём

func _pick_any_extra_attack_card(current: Array) -> Dictionary: # добираем любую атаку
	var avoid_keys := PackedStringArray() # ключи уже выбранных
	for c in current: # по текущим
		if String(c.get("type","")) == "attack": # только атаки
			avoid_keys.append(str(c.get("rid_name","")) + "|" + str(c.get("attack_id",""))) # ключ
	var pool: Array = _collect_attack_cards(3) # собираем пул
	for cand in pool: # ищем неиспользованную
		var key := str(cand.get("rid_name","")) + "|" + str(cand.get("attack_id","")) # ключ
		if not avoid_keys.has(key): return cand # нашли
	return {} # ничего нет

func _rid_dict_by_name(rid_name: String) -> Dictionary: # словарь рида
	if rid_name == "rid_1": return player_attack_one_up # рид 1
	if rid_name == "rid_2": return player_attack_two_up # рид 2
	if rid_name == "rid_3": return player_attack_three_up # рид 3
	return {} # неизвестное имя

func _build_default_attack_candidate() -> Dictionary: # карта дефолта
	if default_attack_id == "" or not player_attack_default.has(default_attack_id): return {} # нет дефолта
	# проверяем, что дефолт активирован в GameStats # важная проверка
	var atk_block = GameStats.stats_player.get("attack", {}) # берём блок атак
	if typeof(atk_block) != TYPE_DICTIONARY or not (atk_block as Dictionary).get(default_attack_id, {}).get("activated", false): return {} # если не активирован
	var levels: Array = player_attack_default[default_attack_id] as Array # уровни 2..N
	var cur_level_with_base: int = int(attack_level_by_id.get(default_attack_id, 1)) # текущий (база=1)
	var next_index: int = cur_level_with_base - 1 # индекс (смещение)
	if next_index >= levels.size(): return {} # максимум достигнут
	var level_dict: Dictionary = levels[next_index] as Dictionary # следующий уровень
	var max_total: int = levels.size() + 1 # максимум с базой
	return { "type": "attack", "rid_name": "default", "attack_id": default_attack_id, "next_level": cur_level_with_base + 1, "max_level": max_total, "title": level_dict.get("title", default_attack_id), "description": level_dict.get("description", "") } # карта

func _build_attack_candidates_distinct_rids(max_count: int) -> Array: # по одному из ридов
	var rid_list: Array = [] # список ридов
	if RIDS_ENABLED >= 1: rid_list.append({ "name": "rid_1", "dict": player_attack_one_up }) # рид 1
	if RIDS_ENABLED >= 2: rid_list.append({ "name": "rid_2", "dict": player_attack_two_up }) # рид 2
	if RIDS_ENABLED >= 3: rid_list.append({ "name": "rid_3", "dict": player_attack_three_up }) # рид 3
	
	var new_rid: Array = [] # неоткрытые риды
	var existing_rid: Array = [] # открытые риды
	for item in rid_list: # перебор
		var rid_name: String = str(item["name"]) # имя
		var rid_dict: Dictionary = item["dict"] as Dictionary # словарь
		var candidate: Dictionary = _candidate_for_rid(rid_name, rid_dict) # кандидат
		if candidate.size() == 0: continue # нечего
		if not unlocked_attack_rids.has(rid_name): new_rid.append(candidate) # в новые
		else: existing_rid.append(candidate) # в открытые
	var picked: Array = [] # итог
	new_rid.shuffle() # перемешиваем
	for c in new_rid: # сначала новые
		if picked.size() >= max_count: break # лимит
		picked.append(c) # добавляем
	if picked.size() < max_count: # добираем
		existing_rid.shuffle() # перемешиваем
		for c in existing_rid:
			if picked.size() >= max_count: break # лимит
			var rid_to_add: String = str(c.get("rid_name", "")) # имя
			var has_same: bool = false # дубль?
			for p in picked:
				if str(p.get("rid_name", "")) == rid_to_add: has_same = true; break # защита
			if not has_same: picked.append(c) # добавляем
	return picked # отдаём

func _candidate_for_rid(rid_name: String, rid_dict: Dictionary) -> Dictionary: # один кандидат рида
	if not unlocked_attack_rids.has(rid_name): # если рид не открыт
		var start: Array = [] # список стартов
		for attack_id in rid_dict.keys(): # по атакам
			var levels: Array = rid_dict[attack_id] as Array # уровни
			if levels.is_empty(): continue # защита
			var lvl1: Dictionary = levels[0] as Dictionary # первый уровень
			start.append({ "type": "attack", "rid_name": rid_name, "attack_id": attack_id, "next_level": 1, "max_level": levels.size(), "title": lvl1.get("title", attack_id), "description": lvl1.get("description", "") }) # карта
		if start.is_empty(): return {} # пусто
		start.shuffle() # перемешиваем
		return start[0] as Dictionary # отдаём
	else: # рид открыт
		var chosen_id: String = str(chosen_attack_id_by_rid.get(rid_name, "")) # выбранная атака
		if chosen_id == "" or not rid_dict.has(chosen_id): return {} # защита
		var levels2: Array = rid_dict[chosen_id] as Array # уровни
		var cur_level: int = int(attack_level_by_id.get(chosen_id, 0)) # текущий
		var max_level: int = levels2.size() # максимум
		if cur_level >= max_level: return {} # на максимуме
		var next_dict: Dictionary = levels2[cur_level] as Dictionary # следующий уровень
		return { "type": "attack", "rid_name": rid_name, "attack_id": chosen_id, "next_level": cur_level + 1, "max_level": max_level, "title": next_dict.get("title", chosen_id), "description": next_dict.get("description", "") } # карта

func on_card_choice_selected(choice: Dictionary) -> void: # обработчик выбора карты
	var choice_type: String = str(choice.get("type", "")) # тип карты
	if choice_type == "passive": _apply_passive_pick(choice) # применяем пассивку
	elif choice_type == "attack": _apply_attack_pick(choice) # применяем атаку
	elif choice_type == "spend": _apply_spend_pick(choice) # применяем стим
	if level_up_screen and level_up_screen.has_method("hide_screen"): level_up_screen.hide_screen() # прячем окно
	
	check_attack_activated.emit() # уведомляем AttackController
	get_tree().paused = false # снимаем паузу

func _apply_passive_pick(ch: Dictionary) -> void: # применение пассивки
	var pid: String = str(ch.get("id", "")) # id пассивки
	var lvl: int = int(ch.get("next_level", 1)) # целевой уровень
	if pid == "": return # защита
	var levels: Array = player_stats_up.get(pid, []) as Array # уровни ветки
	if lvl >= 1 and lvl <= levels.size(): # проверка диапазона
		var level_dict: Dictionary = levels[lvl - 1] as Dictionary # уровень
		var effects: Array = level_dict.get("effects", []) as Array # эффекты
		_apply_effects(effects) # применяем
	passive_level_by_id[pid] = lvl # сохраняем прогресс
	if not owned_passive_ids.has(pid): owned_passive_ids.append(pid) # отмечаем владение

func _apply_attack_pick(ch: Dictionary) -> void: # применение атаки/апа
	var rid_name: String = str(ch.get("rid_name", "")) # имя рида или "default"
	var attack_id: String = str(ch.get("attack_id", "")) # id атаки
	var lvl: int = int(ch.get("next_level", 1)) # целевой уровень
	if attack_id == "": return # защита
	if rid_name == "default": # дефолт
		var levels: Array = player_attack_default.get(attack_id, []) as Array # уровни 2..N
		var arr_index: int = max(0, lvl - 2) # индекс
		if lvl >= 2 and arr_index < levels.size(): # в пределах
			var level_dict: Dictionary = levels[arr_index] as Dictionary # уровень
			var effects: Array = level_dict.get("effects", []) as Array # эффекты
			_apply_effects(effects) # применяем
			attack_level_by_id[attack_id] = lvl # сохраняем
		return # выходим
	var rid_dict: Dictionary = {} # словарь рида
	if rid_name == "rid_1": rid_dict = player_attack_one_up # рид 1
	elif rid_name == "rid_2": rid_dict = player_attack_two_up # рид 2
	elif rid_name == "rid_3": rid_dict = player_attack_three_up # рид 3
	
	var levels2: Array = rid_dict.get(attack_id, []) as Array # уровни
	if lvl >= 1 and lvl <= levels2.size(): # проверка
		var level_dict2: Dictionary = levels2[lvl - 1] as Dictionary # уровень
		var effects2: Array = level_dict2.get("effects", []) as Array # эффекты
		_apply_effects(effects2) # применяем
	if not unlocked_attack_rids.has(rid_name): # если рид выбираем впервые
		unlocked_attack_rids.append(rid_name) # помечаем открыт
		chosen_attack_id_by_rid[rid_name] = attack_id # запоминаем
	attack_level_by_id[attack_id] = lvl # сохраняем уровень

func _apply_spend_pick(ch: Dictionary) -> void: # применение стима
	var sid: String = str(ch.get("id", "")) # id стима
	if sid == "" or not spend_up.has(sid): return # защита
	var sdata: Dictionary = spend_up[sid] as Dictionary # данные стима
	var effects: Array = sdata.get("effects", []) as Array # эффекты
	_apply_effects(effects) # применяем

func _apply_effects(effects: Array) -> void: # запись эффектов в GameStats
	for e in effects: # по эффектам
		var path: String = str((e as Dictionary).get("path", "")) # путь
		if path == "": continue # защита
		var op: String = str((e as Dictionary).get("effect", "set")) # операция
		var val = (e as Dictionary).get("value") # значение
		var holder: Variant = GameStats # узел начала
		var parts: PackedStringArray = path.split(".") # части пути
		if parts.size() == 0: continue # защита
		for i in range(parts.size() - 1): # спускаемся
			var key: String = parts[i] # ключ
			if typeof(holder) == TYPE_DICTIONARY: # словарь?
				var dict_ref := holder as Dictionary # ссылка
				if not dict_ref.has(key): holder = null; break # путь битый
				holder = dict_ref[key] # спуск
			else: # объект
				var got = holder.get(key) # читаем
				if got == null: holder = null; break # путь битый
				holder = got # спуск
		if holder == null: continue # защита
		var leaf: String = parts[parts.size() - 1] # финальный ключ
		var cur_val = null # текущее
		if typeof(holder) == TYPE_DICTIONARY: cur_val = (holder as Dictionary).get(leaf, null) 
		else: cur_val = holder.get(leaf) # читаем
		var new_val = cur_val # по умолчанию без изменений
		match op: # операция
			"set":
				new_val = val # присваиваем
			"add":
				new_val = (cur_val if cur_val != null else 0) + val # складываем
			"mul":
				new_val = (cur_val if cur_val != null else 0) * val # умножаем
			_:
				new_val = val # по умолчанию set
		if typeof(holder) == TYPE_DICTIONARY: (holder as Dictionary)[leaf] = new_val 
		else: holder.set(leaf, new_val) # записываем
		if GameStats.stats_player.has("current_health") and GameStats.stats_player.has("max_health"):
			if GameStats.stats_player["current_health"] > GameStats.stats_player["max_health"]:
				GameStats.stats_player["current_health"] = GameStats.stats_player["max_health"]

func _is_everything_maxed() -> bool: # нет ли вообще доступных карт
	var any_passives: Array = _build_passive_candidates() # собираем пассивки
	if any_passives.size() > 0: return false # если есть пассивки — не максимум
	if _has_any_attack_choices(): return false # если есть атаки — не максимум
	return true # иначе — максимум, показываем стимы

func _has_any_attack_choices() -> bool: # проверка наличия любых атак
	if _rid_has_choice("rid_1") and RIDS_ENABLED >= 1: return true # рид 1
	if _rid_has_choice("rid_2") and RIDS_ENABLED >= 2: return true # рид 2
	if _rid_has_choice("rid_3") and RIDS_ENABLED >= 3: return true # рид 3
	
	if _has_default_attack_upgrade(): return true # дефолтная атака
	return false # ничего нет

func _rid_has_choice(rid_name: String) -> bool: # есть ли выбор по риду
	var rid_dict: Dictionary = _rid_dict_by_name(rid_name) # словарь рида
	if rid_dict.is_empty(): return false # нет рида
	if not unlocked_attack_rids.has(rid_name): # рид не открыт — проверяем старты
		for attack_id in rid_dict.keys(): # по атакам
			var levels: Array = rid_dict[attack_id] as Array # уровни
			if not levels.is_empty(): return true # есть старт
		return false # нет стартов
	var chosen_id: String = str(chosen_attack_id_by_rid.get(rid_name, "")) # выбранная атака
	if chosen_id == "" or not rid_dict.has(chosen_id): return false # защита
	var levels2: Array = rid_dict[chosen_id] as Array # уровни
	var cur_level: int = int(attack_level_by_id.get(chosen_id, 0)) # текущий
	return cur_level < levels2.size() # истина если можно апнуть

func _has_default_attack_upgrade() -> bool: # можно ли апнуть дефолт
	if default_attack_id == "" or not player_attack_default.has(default_attack_id): return false # нет дефолта
	var atk_block = GameStats.stats_player.get("attack", {}) # блок атак
	if typeof(atk_block) != TYPE_DICTIONARY: return false # защита
	var is_active = (atk_block as Dictionary).get(default_attack_id, {}).get("activated", false) # активирован?
	if not is_active: return false # не активен — не считаем
	var levels: Array = player_attack_default[default_attack_id] as Array # уровни 2..N
	var cur_level_with_base: int = int(attack_level_by_id.get(default_attack_id, 1)) # текущий (с базой)
	return (cur_level_with_base - 1) < levels.size() # можно ли апнуть ещё

func _levels_count_for_attack_in_any_rid(attack_id: String) -> int: # (оставлено для совместимости)
	for rid_map in _get_enabled_rid_maps(): # по ридам
		if (rid_map as Dictionary).has(attack_id): return ((rid_map as Dictionary)[attack_id] as Array).size() # уровни
	return 0 # не нашли

func _get_enabled_rid_maps() -> Array: # активные риды
	var maps: Array = [] # сюда
	if RIDS_ENABLED >= 1: maps.append(player_attack_one_up) # rid_1
	if RIDS_ENABLED >= 2: maps.append(player_attack_two_up) # rid_2
	if RIDS_ENABLED >= 3: maps.append(player_attack_three_up) # rid_3
	
	return maps # отдаём

func _pick_spend_cards_by_stock() -> Array: # выбор 1..3 стимов
	var keys: Array = spend_up.keys() # все id
	if keys.is_empty(): return [] # нет стимов
	keys.shuffle() # перемешиваем
	var want: int = 1 if keys.size() == 1 else (2 if keys.size() == 2 else 3) # сколько карт показать
	var res: Array = [] # сюда
	for i in range(want): # берём первые N
		var sid: String = str(keys[i]) # id
		var data: Dictionary = spend_up[sid] as Dictionary # данные
		res.append({ "type": "spend", "id": sid, "title": data.get("title", sid), "description": data.get("description", "") }) # карта
	return res # отдаём
