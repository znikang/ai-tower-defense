extends Node2D

var gold = 500
var lives = 20
var wave = 1
var walls_available = 10
var enemies = []
var towers = []
var walls = []
var bullets = []
var explosions = []
var game_over = false
var selected_mode = 1
var wave_in_progress = false
var total_enemies_in_wave = 0
var enemies_spawned = 0

var castle_pos = Vector2(450, 300)
var castle_size = 80
var castle_sprite: Sprite2D
var castle_shake_timer = 0.0
var castle_shake_intensity = 0.0
var castle_blink_timer = 0.0

var wall_texture = preload("res://assets/images/wall.png")
var castle_texture = preload("res://assets/images/castle.png")

var tower_types = {
	1: {"name": "Basic", "range": 120, "damage": 10, "shoot_speed": 1.0, "cost": 100, "color": Color.GREEN, "explosion_range": 30, "type": "normal"},
	2: {"name": "Sniper", "range": 180, "damage": 30, "shoot_speed": 2.0, "cost": 200, "color": Color.DARK_BLUE, "explosion_range": 50, "type": "normal"},
	3: {"name": "Gun", "range": 80, "damage": 5, "shoot_speed": 0.3, "cost": 150, "color": Color.RED, "explosion_range": 20, "type": "normal"},
	4: {"name": "Freeze", "range": 150, "damage": 0, "shoot_speed": 1.5, "cost": 180, "color": Color.CYAN, "freeze_time": 2.0, "type": "freeze"},
	5: {"name": "Laser", "range": 160, "damage": 20, "shoot_speed": 0.0, "cost": 220, "color": Color.LIGHT_GRAY, "type": "laser"}
}

var enemy_types = {
	1: {"name": "Weak", "hp": 20, "speed": 100.0, "color": Color.YELLOW, "reward": 10},
	2: {"name": "Normal", "hp": 40, "speed": 80.0, "color": Color.WHITE, "reward": 20},
	3: {"name": "Strong", "hp": 80, "speed": 60.0, "color": Color.RED, "reward": 50}
}

var ui_buttons = []
var frozen_enemies = {}
var laser_targets = {}
var next_enemy_id = 0

# 追蹤所有動態建立的節點
var dynamic_nodes = []

func _ready():
	print("Defense Mode Started!")
	castle_sprite = Sprite2D.new()
	castle_sprite.texture = castle_texture
	castle_sprite.position = castle_pos
	castle_sprite.scale = Vector2(1.5, 1.5)
	add_child(castle_sprite)
	dynamic_nodes.append(castle_sprite)
	create_ui()
	queue_redraw()
	await get_tree().create_timer(2.0).timeout
	start_wave()

func play_sound(sound_type: String):
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	var sound = null
	match sound_type:
		"castle_hit":
			sound = load("res://assets/sounds/castle_hit.wav")
		"shoot":
			sound = load("res://assets/sounds/shoot.wav")
		"explosion":
			sound = load("res://assets/sounds/explosion.wav")
	if sound:
		audio_player.stream = sound
		audio_player.play()
		await get_tree().create_timer(1.0).timeout
		audio_player.queue_free()

func create_ui():
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.75
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 3)
	ui_layer.add_child(vbox)

	var hbox1 = HBoxContainer.new()
	hbox1.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox1)

	var btn1 = Button.new()
	btn1.text = "GREEN\nBASIC\n100G"
	btn1.toggle_mode = true
	btn1.button_pressed = true
	btn1.custom_minimum_size = Vector2(0, 60)
	btn1.pressed.connect(func(): _on_weapon_selected(1))
	hbox1.add_child(btn1)
	ui_buttons.append(btn1)

	var btn3 = Button.new()
	btn3.text = "BLUE\nSNIPER\n200G"
	btn3.toggle_mode = true
	btn3.custom_minimum_size = Vector2(0, 60)
	btn3.pressed.connect(func(): _on_weapon_selected(2))
	hbox1.add_child(btn3)
	ui_buttons.append(btn3)

	var btn_gun = Button.new()
	btn_gun.text = "RED\nGUN\n150G"
	btn_gun.toggle_mode = true
	btn_gun.custom_minimum_size = Vector2(0, 60)
	btn_gun.pressed.connect(func(): _on_weapon_selected(3))
	hbox1.add_child(btn_gun)
	ui_buttons.append(btn_gun)

	var btn_freeze = Button.new()
	btn_freeze.text = "CYAN\nFREEZE\n180G"
	btn_freeze.toggle_mode = true
	btn_freeze.custom_minimum_size = Vector2(0, 60)
	btn_freeze.pressed.connect(func(): _on_weapon_selected(4))
	hbox1.add_child(btn_freeze)
	ui_buttons.append(btn_freeze)

	var btn_laser = Button.new()
	btn_laser.text = "LASER\nLASER\n220G"
	btn_laser.toggle_mode = true
	btn_laser.custom_minimum_size = Vector2(0, 60)
	btn_laser.pressed.connect(func(): _on_weapon_selected(5))
	hbox1.add_child(btn_laser)
	ui_buttons.append(btn_laser)

	var hbox2 = HBoxContainer.new()
	hbox2.add_theme_constant_override("separation", 5)
	vbox.add_child(hbox2)

	var btn2 = Button.new()
	btn2.text = "WALL\nWALL\n1 PC"
	btn2.toggle_mode = true
	btn2.custom_minimum_size = Vector2(0, 60)
	btn2.pressed.connect(func(): _on_weapon_selected(6))
	hbox2.add_child(btn2)
	ui_buttons.append(btn2)

	var reset_btn = Button.new()
	reset_btn.text = "RESET"
	reset_btn.custom_minimum_size = Vector2(0, 60)
	reset_btn.pressed.connect(func(): reset_game())
	hbox2.add_child(reset_btn)

func _on_weapon_selected(mode: int):
	selected_mode = mode
	for i in range(ui_buttons.size()):
		ui_buttons[i].button_pressed = (i + 1 == mode)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			reset_game()
			return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game_over:
			return
		var mouse_y = get_global_mouse_position().y
		var screen_height = get_viewport_rect().size.y
		if mouse_y > screen_height * 0.75:
			return

		var pos = get_global_mouse_position()
		match selected_mode:
			1, 2, 3, 4, 5:
				var tower_info = tower_types[selected_mode]
				if gold >= tower_info["cost"]:
					gold -= tower_info["cost"]
					place_tower(pos, selected_mode)
					queue_redraw()
			6:
				if walls_available > 0:
					walls_available -= 1
					place_wall(pos)
					queue_redraw()

func place_tower(pos, tower_type):
	var tower_info = tower_types[tower_type]
	var tower_obj = ColorRect.new()
	tower_obj.size = Vector2(16, 16)
	tower_obj.position = pos - Vector2(8, 8)
	tower_obj.color = tower_info["color"]
	add_child(tower_obj)
	dynamic_nodes.append(tower_obj)

	var tower = {
		"pos": pos,
		"type": tower_type,
		"range": tower_info["range"],
		"damage": tower_info["damage"],
		"shoot_speed": tower_info["shoot_speed"],
		"explosion_range": tower_info.get("explosion_range", 0),
		"obj": tower_obj,
		"shoot_timer": 0.0,
		"target": null
	}
	towers.append(tower)

func place_wall(pos):
	var wall_obj = Sprite2D.new()
	wall_obj.texture = wall_texture
	wall_obj.position = pos
	add_child(wall_obj)
	dynamic_nodes.append(wall_obj)

	var wall = {
		"pos": pos,
		"obj": wall_obj,
		"rect": Rect2(pos - Vector2(16, 16), Vector2(32, 32)),
		"hp": 3,
		"max_hp": 3
	}
	walls.append(wall)

func start_wave():
	if wave_in_progress:
		return
	wave_in_progress = true

	var enemy_list = generate_wave_enemies()
	total_enemies_in_wave = enemy_list.size()
	enemies_spawned = 0
	walls_available += 5

	for enemy_type in enemy_list:
		var random_delay = randf_range(0.2, 0.8)
		await get_tree().create_timer(random_delay).timeout
		if game_over:
			return
		spawn_enemy(enemy_type)

	while enemies.size() > 0 and not game_over:
		await get_tree().create_timer(0.5).timeout

	wave_in_progress = false

	if not game_over:
		await get_tree().create_timer(2.0).timeout
		if not game_over:
			wave += 1
			start_wave()

func generate_wave_enemies() -> Array:
	var enemy_list = []
	if wave == 1:
		for i in range(5): enemy_list.append(1)
	elif wave == 2:
		for i in range(3): enemy_list.append(1)
		for i in range(3): enemy_list.append(2)
	elif wave == 3:
		for i in range(2): enemy_list.append(1)
		for i in range(3): enemy_list.append(2)
		enemy_list.append(3)
	elif wave >= 4:
		for i in range(2): enemy_list.append(1)
		for i in range(wave): enemy_list.append(2)
		for i in range(wave - 2): enemy_list.append(3)
	return enemy_list

func spawn_enemy(enemy_type: int):
	var enemy_info = enemy_types[enemy_type]
	var enemy_obj = Sprite2D.new()
	var cockroach_texture = load("res://assets/images/cockroach.png")
	if cockroach_texture:
		enemy_obj.texture = cockroach_texture
	enemy_obj.scale = Vector2(1.5, 1.5)
	match enemy_type:
		1: enemy_obj.self_modulate = Color.YELLOW
		2: enemy_obj.self_modulate = Color.WHITE
		3: enemy_obj.self_modulate = Color.RED
	add_child(enemy_obj)
	dynamic_nodes.append(enemy_obj)

	var spawn_pos = get_random_edge_position()
	var enemy = {
		"type": enemy_type,
		"hp": enemy_info["hp"],
		"max_hp": enemy_info["hp"],
		"x": spawn_pos.x,
		"y": spawn_pos.y,
		"speed": enemy_info["speed"],
		"reward": enemy_info["reward"],
		"obj": enemy_obj,
		"direction": Vector2.ZERO,
		"wall_collision_timer": 0.0,
		"redirect_timer": 0.0,
		"stuck_timer": 0.0,
		"last_pos": spawn_pos,
		"hit_wall_idx": -1
	}
	enemies.append(enemy)
	enemies_spawned += 1

func get_random_edge_position() -> Vector2:
	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y
	var edge = randi() % 4
	match edge:
		0: return Vector2(randf_range(0, screen_width), 0)
		1: return Vector2(randf_range(0, screen_width * 0.8), screen_height * 0.8)
		2: return Vector2(0, randf_range(0, screen_height * 0.8))
		3: return Vector2(screen_width, randf_range(0, screen_height * 0.8))
	return Vector2.ZERO

func check_wall_collision(enemy_pos: Vector2, _direction: Vector2) -> int:
	var enemy_rect = Rect2(enemy_pos - Vector2(10, 10), Vector2(20, 20))
	for w_idx in range(walls.size()):
		if enemy_rect.intersects(walls[w_idx]["rect"]):
			return w_idx
	return -1

func rotate_direction(direction: Vector2, angle_degrees: float) -> Vector2:
	var angle_rad = deg_to_rad(angle_degrees)
	return Vector2(
		direction.x * cos(angle_rad) - direction.y * sin(angle_rad),
		direction.x * sin(angle_rad) + direction.y * cos(angle_rad)
	).normalized()

func get_turn_directions(direction: Vector2) -> Array:
	var result = []
	for angle in [45.0, 90.0, 135.0, -45.0, -90.0, -135.0]:
		result.append(rotate_direction(direction, angle))
	return result

func trigger_castle_damage():
	play_sound.call_deferred("castle_hit")
	castle_shake_timer = 0.3
	castle_shake_intensity = 8.0
	castle_blink_timer = 0.3

func _process(delta):
	if game_over:
		return

	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y

	castle_shake_timer -= delta
	castle_blink_timer -= delta

	if is_instance_valid(castle_sprite):
		if castle_blink_timer > 0:
			var blink_phase = int(castle_blink_timer * 10) % 2
			castle_sprite.modulate = Color.WHITE if blink_phase == 0 else Color(1.2, 0.8, 0.8)
		else:
			castle_sprite.modulate = Color.WHITE
		var shake_offset = Vector2.ZERO
		if castle_shake_timer > 0:
			shake_offset = Vector2(randf_range(-castle_shake_intensity, castle_shake_intensity),
								   randf_range(-castle_shake_intensity, castle_shake_intensity))
		castle_sprite.position = castle_pos + shake_offset

	# 更新敵人
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if not is_instance_valid(enemy["obj"]):
			enemies.remove_at(i)
			continue

		if enemy["direction"] == Vector2.ZERO:
			enemy["direction"] = (castle_pos - Vector2(enemy["x"], enemy["y"])).normalized()

		enemy["wall_collision_timer"] -= delta
		enemy["redirect_timer"] -= delta
		enemy["stuck_timer"] -= delta

		var next_pos = Vector2(enemy["x"], enemy["y"]) + enemy["direction"] * enemy["speed"] * delta

		if next_pos.x < -50 or next_pos.x > screen_width + 50 or next_pos.y < -50 or next_pos.y > screen_height * 0.8 + 50:
			enemy["direction"] = (castle_pos - Vector2(enemy["x"], enemy["y"])).normalized()
			enemy["redirect_timer"] = 1.0
			next_pos = Vector2(enemy["x"], enemy["y"]) + enemy["direction"] * enemy["speed"] * delta

		var wall_idx = check_wall_collision(next_pos, enemy["direction"])
		if wall_idx >= 0:
			if enemy["wall_collision_timer"] <= 0 and enemy["stuck_timer"] <= 0:
				if enemy["hit_wall_idx"] != wall_idx:
					walls[wall_idx]["hp"] -= 1
					enemy["hit_wall_idx"] = wall_idx
					if walls[wall_idx]["hp"] <= 0:
						if is_instance_valid(walls[wall_idx]["obj"]):
							walls[wall_idx]["obj"].queue_free()
						walls.remove_at(wall_idx)

				var turn_options = get_turn_directions(enemy["direction"])
				var available = []
				for d in turn_options:
					if check_wall_collision(Vector2(enemy["x"], enemy["y"]) + d * enemy["speed"] * delta, d) < 0:
						available.append(d)
				enemy["direction"] = available[randi() % available.size()] if available.size() > 0 else turn_options[randi() % turn_options.size()]
				enemy["wall_collision_timer"] = 0.2
				enemy["stuck_timer"] = 0.4
				enemy["redirect_timer"] = 1.5
		else:
			enemy["hit_wall_idx"] = -1
			enemy["x"] = next_pos.x
			enemy["y"] = next_pos.y

		if enemy["redirect_timer"] <= 0:
			var to_castle = (castle_pos - Vector2(enemy["x"], enemy["y"])).normalized()
			if enemy["direction"].dot(to_castle) < 0.3:
				enemy["direction"] = to_castle

		enemy["obj"].position = Vector2(enemy["x"], enemy["y"]) - Vector2(8, 8)
		enemy["last_pos"] = Vector2(enemy["x"], enemy["y"])

		if enemy["hp"] <= 0:
			gold += enemy["reward"]
			if is_instance_valid(enemy["obj"]):
				enemy["obj"].queue_free()
			enemies.remove_at(i)
			continue

		if Vector2(enemy["x"], enemy["y"]).distance_to(castle_pos) < 60:
			lives -= 1
			trigger_castle_damage()
			if is_instance_valid(enemy["obj"]):
				enemy["obj"].queue_free()
			enemies.remove_at(i)
			if lives <= 0:
				game_over = true

	# 更新塔
	for tower in towers:
		if not is_instance_valid(tower["obj"]):
			continue
		tower["shoot_timer"] -= delta
		var target = null
		var closest_dist = tower["range"]
		for enemy in enemies:
			if not is_instance_valid(enemy["obj"]):
				continue
			var dist = tower["pos"].distance_to(Vector2(enemy["x"], enemy["y"]))
			if dist < closest_dist:
				closest_dist = dist
				target = enemy

		if tower["shoot_timer"] <= 0 and target:
			play_sound.call_deferred("shoot")
			var bullet_obj = ColorRect.new()
			bullet_obj.size = Vector2(8, 8)
			bullet_obj.color = Color.YELLOW
			add_child(bullet_obj)
			bullets.append({
				"pos": tower["pos"],
				"target_enemy": target,
				"speed": 400.0,
				"damage": tower["damage"],
				"explosion_range": tower["explosion_range"],
				"obj": bullet_obj,
				"lifetime": 5.0
			})
			tower["shoot_timer"] = tower["shoot_speed"]

	# 更新子彈
	for i in range(bullets.size() - 1, -1, -1):
		var bullet = bullets[i]
		if not is_instance_valid(bullet["obj"]):
			bullets.remove_at(i)
			continue

		bullet["lifetime"] -= delta
		if bullet["lifetime"] <= 0 or not bullet["target_enemy"] in enemies:
			if is_instance_valid(bullet["obj"]):
				bullet["obj"].queue_free()
			bullets.remove_at(i)
			continue

		var target_pos = Vector2(bullet["target_enemy"]["x"], bullet["target_enemy"]["y"])
		var direction = (target_pos - bullet["pos"]).normalized()
		bullet["pos"] += direction * bullet["speed"] * delta
		bullet["obj"].position = bullet["pos"] - Vector2(4, 4)

		if bullet["pos"].distance_to(target_pos) < 12:
			create_explosion(bullet["pos"], bullet["explosion_range"], bullet["damage"])
			if is_instance_valid(bullet["obj"]):
				bullet["obj"].queue_free()
			bullets.remove_at(i)

	# 更新爆炸
	for i in range(explosions.size() - 1, -1, -1):
		explosions[i]["lifetime"] -= delta
		if explosions[i]["lifetime"] <= 0:
			explosions.remove_at(i)
			queue_redraw()

	var label = get_node_or_null("UI/Label")
	if label:
		if game_over:
			label.text = "GAME OVER! Lives: %d\nPress R to reset" % lives
			label.add_theme_color_override("font_color", Color.RED)
		else:
			label.text = "Gold:%d | Lives:%d | Walls:%d | Wave %d (%d/%d)" % [gold, lives, walls_available, wave, enemies.size(), total_enemies_in_wave]
			label.add_theme_color_override("font_color", Color.WHITE)

	queue_redraw()

func create_explosion(pos: Vector2, explosion_range: float, damage: int):
	play_sound.call_deferred("explosion")
	explosions.append({"pos": pos, "range": explosion_range, "lifetime": 0.3})
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if pos.distance_to(Vector2(enemy["x"], enemy["y"])) < explosion_range:
			enemy["hp"] -= damage
			if enemy["hp"] <= 0:
				gold += enemy["reward"]
				if is_instance_valid(enemy["obj"]):
					enemy["obj"].queue_free()
				enemies.remove_at(i)

func _draw():
	for tower in towers:
		if not is_instance_valid(tower["obj"]):
			continue
		draw_circle(tower["pos"], tower["range"], Color(1, 1, 1, 0.1))
		draw_arc(tower["pos"], tower["range"], 0, TAU, 32, Color(1, 1, 1, 0.3), 1.0)

	for enemy in enemies:
		if not is_instance_valid(enemy["obj"]):
			continue
		var enemy_pos = Vector2(enemy["x"], enemy["y"])
		draw_rect(Rect2(enemy_pos.x - 16, enemy_pos.y - 30, 24, 4), Color.BLACK)
		var hp_ratio = float(enemy["hp"]) / float(enemy["max_hp"])
		draw_rect(Rect2(enemy_pos.x - 16, enemy_pos.y - 30, 24 * hp_ratio, 4), Color.GREEN.lerp(Color.RED, 1.0 - hp_ratio))
		draw_rect(Rect2(enemy_pos.x - 16, enemy_pos.y - 30, 24, 4), Color.WHITE, false, 1.0)

	for wall in walls:
		if not is_instance_valid(wall["obj"]):
			continue
		var hp_bar_y = wall["pos"].y + 20
		draw_rect(Rect2(wall["pos"].x - 12, hp_bar_y, 24, 2), Color.BLACK)
		var hp_ratio = float(wall["hp"]) / float(wall["max_hp"])
		draw_rect(Rect2(wall["pos"].x - 12, hp_bar_y, 24 * hp_ratio, 2), Color.CYAN.lerp(Color.RED, 1.0 - hp_ratio))

	for explosion in explosions:
		var exp_pos = explosion["pos"]
		var progress = 1.0 - (explosion["lifetime"] / 0.3)
		draw_circle(exp_pos, explosion["range"] * (1.0 + progress * 0.5), Color(1, 1, 0, 0.4 * (1.0 - progress)))
		draw_circle(exp_pos, explosion["range"] * 0.8, Color(1, 0.6, 0, 0.6 * (1.0 - progress)))
		draw_circle(exp_pos, explosion["range"] * 0.4, Color(1, 0.2, 0, 1.0 * (1.0 - progress)))

func reset_game():
	# 停止所有正在執行的 await
	game_over = true
	wave_in_progress = false

	# 安全清除所有動態節點
	for enemy in enemies:
		if is_instance_valid(enemy["obj"]):
			enemy["obj"].queue_free()
	for tower in towers:
		if is_instance_valid(tower["obj"]):
			tower["obj"].queue_free()
	for wall in walls:
		if is_instance_valid(wall["obj"]):
			wall["obj"].queue_free()
	for bullet in bullets:
		if is_instance_valid(bullet["obj"]):
			bullet["obj"].queue_free()
	if is_instance_valid(castle_sprite):
		castle_sprite.queue_free()

	# 清空所有陣列
	enemies.clear()
	towers.clear()
	walls.clear()
	bullets.clear()
	explosions.clear()
	dynamic_nodes.clear()

	# 重設狀態
	gold = 500
	lives = 20
	wave = 1
	walls_available = 10
	game_over = false
	selected_mode = 1
	total_enemies_in_wave = 0
	enemies_spawned = 0
	castle_shake_timer = 0.0
	castle_blink_timer = 0.0

	for i in range(ui_buttons.size()):
		ui_buttons[i].button_pressed = (i == 0)

	# 等一個 frame 讓 queue_free 執行完
	await get_tree().process_frame

	# 重建城堡
	castle_sprite = Sprite2D.new()
	castle_sprite.texture = castle_texture
	castle_sprite.position = castle_pos
	castle_sprite.scale = Vector2(1.5, 1.5)
	add_child(castle_sprite)
	dynamic_nodes.append(castle_sprite)

	var label = get_node_or_null("UI/Label")
	if label:
		label.text = "Gold:500 | Lives:20 | Walls:10 | Wave 1"
		label.add_theme_color_override("font_color", Color.WHITE)

	queue_redraw()

	await get_tree().create_timer(0.5).timeout
	start_wave()
