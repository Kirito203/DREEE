extends TextureProgressBar

func _process(_delta): # Вызывается каждый кадр
	var player_max_health = GameStats.stats_player["max_health"]
	var player_current_health = GameStats.stats_player["current_health"]
	# Проверка, чтобы не делить на 0
	if player_max_health > 0:
		value = player_current_health * 100 / player_max_health # Обновляем прогрессбар
