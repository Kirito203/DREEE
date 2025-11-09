extends TextureProgressBar

func _process(_delta): # Вызывается каждый кадр
	var player_xp_to_next_level = GameStats.stats_player["xp_to_next_level"]
	var player_current_xp = GameStats.stats_player["current_xp"]
	# Проверка, чтобы не делить на 0
	if player_xp_to_next_level > 0:
		value = player_current_xp * 100 / player_xp_to_next_level # Обновляем прогрессбар
