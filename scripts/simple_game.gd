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

func _ready():
	print("Defense Mode Started!")
	
	castle_sprite = Sprite2D.new()
	castle_sprite.texture = castle_texture
	castle_sprite.position = castle_pos
	castle_sprite.scale = Vector2(1.5, 1.5)
	add_child(castle_sprite)
	
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
	
	# 第一排塔
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
	btn3.pressed.connect(func(): _on_weapon_selected(3))
	hbox1.add_child(btn3)
	ui_buttons.append(btn3)
	
	var btn_gun = Button.new()
	btn_gun.text = "RED\nGUN\n150G"
	btn_gun.toggle_mode = true
	btn_gun.custom_minimum_size = Vector2(0, 60)
	btn_gun.pressed.connect(func(): _on_weapon_selected(3))
	hbox1.add_child(btn_gun)
	
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
	
	# 第二排 - 牆和重置
	var hbox2 = HBoxContainer.new()
	hbox2.add_theme_constant_override("separation", 5)
	vbox.add_child(hbox2)
	
	var btn2 = Button.new()
	btn2.text = "WALL\nWALL\n1 PC"
	btn2.toggle_mode = true
	btn2.custom_minimum_size = Vector2(0, 60)
	btn2.pressed.connect(func(): _on_weapon_selected(2))
	hbox2.add_child(btn2)
	ui_buttons.append(btn2)
	
	var reset_btn = Button.new()
	reset_btn.text = "RESET"
	reset_btn.custom_minimum_size = Vector2(0, 60)
	reset_btn.pressed.connect(func(): reset_game())
	hbox2.add_child(reset_btn)

func _on_weapon_selected(mode: int):
	selected_mode = mode
	print("Mode selected: %d" % mode)
	for i in range(ui_buttons.size()):
		ui_buttons[i].button_pressed = (i + 1 == mode)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			selected_mode = 1
			ui_buttons[0].button_pressed = true
			ui_buttons[1].button_pressed = false
			ui_buttons[2].button_pressed = false
		elif event.keycode == KEY_2:
			selected_mode = 2
			ui_buttons[0].button_pressed = false
			ui_buttons[1].button_pressed = true
			ui_buttons[2].button_pressed = false
		elif event.keycode == KEY_3:
			selected_mode = 3
			ui_buttons[0].button_pressed = false
			ui_buttons[1].button_pressed = false
			ui_buttons[2].button_pressed = true
		elif event.keycode == KEY_R:
			reset_game()
			return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_y = get_global_mouse_position().y
		var screen_height = get_viewport_rect().size.y
		
		# 按鈕區域 (0.75 - 1.0) - 直接返回，不放置塔
		if mouse_y > screen_height * 0.75:
			return
		
		var pos = get_global_mouse_position()
		
		if selected_mode == 1:
			var tower_info = tower_types[1]
			if not game_over and gold >= tower_info["cost"]:
				gold -= tower_info["cost"]
				place_tower(pos, 1)
				queue_redraw()
		elif selected_mode == 2:
			if not game_over and walls_available > 0:
				walls_available -= 1
				place_wall(pos)
				queue_redraw()
		elif selected_mode == 3:
			var tower_info = tower_types[3]
			if not game_over and gold >= tower_info["cost"]:
				gold -= tower_info["cost"]
				place_tower(pos, 3)
				queue_redraw()
		elif selected_mode == 4:
			var tower_info = tower_types[4]
			if not game_over and gold >= tower_info["cost"]:
				gold -= tower_info["cost"]
				place_tower(pos, 4)
				queue_redraw()
		elif selected_mode == 5:
			var tower_info = tower_types[5]
			if not game_over and gold >= tower_info["cost"]:
				gold -= tower_info["cost"]
				place_tower(pos, 5)
				queue_redraw()

func place_tower(pos, tower_type):
	var tower_info = tower_types[tower_type]
	var tower_obj = ColorRect.new()
	tower_obj.size = Vector2(16, 16)
	tower_obj.position = pos - Vector2(8, 8)
	tower_obj.color = tower_info["color"]
	add_child(tower_obj)
	
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
	
	var wall = {
		"pos": pos,
		"obj": wall_obj,
		"rect": Rect2(pos - Vector2(16, 16), Vector2(32, 32)),
		"hp": 3,
		"max_hp": 3
	}
	walls.append(wall)
	
	var push_range = 80.0
	var push_force = 150.0
	
	for enemy in enemies:
		var enemy_pos = Vector2(enemy["x"], enemy["y"])
		var dist = pos.distance_to(enemy_pos)
		
		if dist < push_range:
			var push_dir = (enemy_pos - pos).normalized()
			enemy["x"] += push_dir.x * push_force
			enemy["y"] += push_dir.y * push_force
			enemy["redirect_timer"] = 1.0

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
		if not game_over:
			spawn_enemy(enemy_type)
	
	while enemies.size() > 0 and not game_over:
		await get_tree().create_timer(0.5).timeout
	
	wave_in_progress = false
	
	if not game_over:
		await get_tree().create_timer(2.0).timeout
		wave += 1
		start_wave()

func generate_wave_enemies() -> Array:
	var enemy_list = []
	
	if wave == 1:
		for i in range(5):
			enemy_list.append(1)
	elif wave == 2:
		for i in range(3):
			enemy_list.append(1)
		for i in range(3):
			enemy_list.append(2)
	elif wave == 3:
		for i in range(2):
			enemy_list.append(1)
		for i in range(3):
			enemy_list.append(2)
		enemy_list.append(3)
	elif wave >= 4:
		for i in range(2):
			enemy_list.append(1)
		for i in range(wave):
			enemy_list.append(2)
		for i in range(wave - 2):
			enemy_list.append(3)
	
	return enemy_list

func spawn_enemy(enemy_type: int):
	var enemy_info = enemy_types[enemy_type]
	
	var enemy_obj = Sprite2D.new()
	var cockroach_texture = load("res://assets/images/cockroach.png")
	if cockroach_texture:
		enemy_obj.texture = cockroach_texture
	else:
		var rect = ColorRect.new()
		rect.size = Vector2(16, 16)
		rect.color = enemy_info["color"]
		enemy_obj = rect
	
	enemy_obj.scale = Vector2(1.5, 1.5)
	
	if enemy_obj is Sprite2D:
		match enemy_type:
			1:
				enemy_obj.self_modulate = Color.YELLOW
			2:
				enemy_obj.self_modulate = Color.WHITE
			3:
				enemy_obj.self_modulate = Color.RED
	
	add_child(enemy_obj)
	
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
	
	var pos = Vector2()
	match edge:
		0:
			pos = Vector2(randf_range(0, screen_width), 0)
		1:
			pos = Vector2(randf_range(0, screen_width * 0.8), screen_height * 0.8)
		2:
			pos = Vector2(0, randf_range(0, screen_height * 0.8))
		3:
			pos = Vector2(screen_width, randf_range(0, screen_height * 0.8))
	
	return pos

func check_wall_collision(enemy_pos: Vector2, _direction: Vector2) -> int:
	var enemy_rect = Rect2(enemy_pos - Vector2(10, 10), Vector2(20, 20))
	
	for w_idx in range(walls.size()):
		var wall = walls[w_idx]
		if enemy_rect.intersects(wall["rect"]):
			return w_idx
	
	return -1

func rotate_direction(direction: Vector2, angle_degrees: float) -> Vector2:
	var angle_rad = deg_to_rad(angle_degrees)
	var cos_a = cos(angle_rad)
	var sin_a = sin(angle_rad)
	return Vector2(direction.x * cos_a - direction.y * sin_a, direction.x * sin_a + direction.y * cos_a).normalized()

func get_turn_directions(direction: Vector2) -> Array:
	var angles = [45.0, 90.0, 135.0, -45.0, -90.0, -135.0]
	var result = []
	for angle in angles:
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
	
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		
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
						walls[wall_idx]["obj"].queue_free()
						walls.remove_at(wall_idx)
				
				var turn_options = get_turn_directions(enemy["direction"])
				var available_directions = []
				for turn_dir in turn_options:
					var turn_pos = Vector2(enemy["x"], enemy["y"]) + turn_dir * enemy["speed"] * delta
					if check_wall_collision(turn_pos, turn_dir) < 0:
						available_directions.append(turn_dir)
				
				if available_directions.size() > 0:
					enemy["direction"] = available_directions[randi() % available_directions.size()]
				else:
					enemy["direction"] = turn_options[randi() % turn_options.size()]
				
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
		
		var enemy_pos = Vector2(enemy["x"], enemy["y"])
		enemy["obj"].position = enemy_pos - Vector2(8, 8)
		enemy["last_pos"] = enemy_pos
		
		if enemy["hp"] <= 0:
			gold += enemy["reward"]
			enemy["obj"].queue_free()
			enemies.remove_at(i)
			continue
		
		if enemy_pos.distance_to(castle_pos) < 60:
			lives -= 1
			trigger_castle_damage()
			enemy["obj"].queue_free()
			enemies.remove_at(i)
			if lives <= 0:
				game_over = true
	
	for tower in towers:
		tower["shoot_timer"] -= delta
		
		var target = null
		var closest_dist = tower["range"]
		for enemy in enemies:
			var enemy_pos = Vector2(enemy["x"], enemy["y"])
			var dist = tower["pos"].distance_to(enemy_pos)
			if dist < closest_dist:
				closest_dist = dist
				target = enemy
		
		var tower_type = tower_types[tower["type"]]["type"]
		
		if tower_type == "normal" and tower["shoot_timer"] <= 0 and target:
			play_sound.call_deferred("shoot")
			var bullet_obj = ColorRect.new()
			bullet_obj.size = Vector2(8, 8)
			bullet_obj.color = Color.YELLOW
			add_child(bullet_obj)
			
			var bullet = {
				"pos": tower["pos"],
				"target_enemy": target,
				"speed": 400.0,
				"damage": tower["damage"],
				"explosion_range": tower["explosion_range"],
				"obj": bullet_obj,
				"lifetime": 5.0
			}
			bullets.append(bullet)
			tower["shoot_timer"] = tower["shoot_speed"]
	
	for i in range(bullets.size() - 1, -1, -1):
		var bullet = bullets[i]
		bullet["lifetime"] -= delta
		
		if not bullet["target_enemy"] in enemies:
			bullet["obj"].queue_free()
			bullets.remove_at(i)
			continue
		
		if bullet["lifetime"] <= 0:
			bullet["obj"].queue_free()
			bullets.remove_at(i)
			continue
		
		var target_pos = Vector2(bullet["target_enemy"]["x"], bullet["target_enemy"]["y"])
		var direction = (target_pos - bullet["pos"]).normalized()
		bullet["pos"] += direction * bullet["speed"] * delta
		bullet["obj"].position = bullet["pos"] - Vector2(4, 4)
		
		if bullet["pos"].distance_to(target_pos) < 12:
			create_explosion(bullet["pos"], bullet["explosion_range"], bullet["damage"])
			bullet["obj"].queue_free()
			bullets.remove_at(i)
	
	for i in range(explosions.size() - 1, -1, -1):
		var explosion = explosions[i]
		explosion["lifetime"] -= delta
		if explosion["lifetime"] <= 0:
			explosions.remove_at(i)
			queue_redraw()
	
	var label = get_node("UI/Label")
	if game_over:
		label.text = "GAME OVER! Lives: %d\nPress R to reset" % lives
		label.add_theme_color_override("font_color", Color.RED)
	else:
		label.text = "Gold:%d | Lives:%d | Walls:%d | Wave %d (%d/%d)" % [gold, lives, walls_available, wave, enemies.size(), total_enemies_in_wave]
		label.add_theme_color_override("font_color", Color.WHITE)
	
	queue_redraw()

func create_explosion(pos: Vector2, explosion_range: float, damage: int):
	play_sound.call_deferred("explosion")
	var explosion = {
		"pos": pos,
		"range": explosion_range,
		"lifetime": 0.3
	}
	explosions.append(explosion)
	
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		var enemy_pos = Vector2(enemy["x"], enemy["y"])
		var dist = pos.distance_to(enemy_pos)
		
		if dist < explosion_range:
			enemy["hp"] -= damage
			
			if enemy["hp"] <= 0:
				gold += enemy["reward"]
				enemy["obj"].queue_free()
				enemies.remove_at(i)

func _draw():
	for tower in towers:
		draw_circle(tower["pos"], tower["range"], Color(1, 1, 1, 0.1))
		draw_arc(tower["pos"], tower["range"], 0, TAU, 32, Color(1, 1, 1, 0.3), 1.0)
	
	for enemy in enemies:
		var enemy_pos = Vector2(enemy["x"], enemy["y"])
		draw_rect(Rect2(enemy_pos.x - 16, enemy_pos.y - 30, 24, 4), Color.BLACK)
		var hp_ratio = float(enemy["hp"]) / float(enemy["max_hp"])
		var bar_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_ratio)
		draw_rect(Rect2(enemy_pos.x - 16, enemy_pos.y - 30, 24 * hp_ratio, 4), bar_color)
		draw_rect(Rect2(enemy_pos.x - 16, enemy_pos.y - 30, 24, 4), Color.WHITE, false, 1.0)
	
	for wall in walls:
		var hp_bar_y = wall["pos"].y + 20
		draw_rect(Rect2(wall["pos"].x - 12, hp_bar_y, 24, 2), Color.BLACK)
		var hp_ratio = float(wall["hp"]) / float(wall["max_hp"])
		var bar_color = Color.CYAN.lerp(Color.RED, 1.0 - hp_ratio)
		draw_rect(Rect2(wall["pos"].x - 12, hp_bar_y, 24 * hp_ratio, 2), bar_color)
	
	for explosion in explosions:
		var exp_pos = explosion["pos"]
		var progress = 1.0 - (explosion["lifetime"] / 0.3)
		
		var outer_range = explosion["range"] * (1.0 + progress * 0.5)
		draw_circle(exp_pos, outer_range, Color(1, 1, 0, 0.4 * (1.0 - progress)))
		
		var middle_range = explosion["range"] * 0.8
		draw_circle(exp_pos, middle_range, Color(1, 0.6, 0, 0.6 * (1.0 - progress)))
		
		var inner_range = explosion["range"] * 0.4
		draw_circle(exp_pos, inner_range, Color(1, 0.2, 0, 1.0 * (1.0 - progress)))
		
		draw_arc(exp_pos, explosion["range"], 0, TAU, 32, Color(1, 0.5, 0, 0.8 * (1.0 - progress)), 2.0)
		
		var particle_count = 8
		for p in range(particle_count):
			var angle = (TAU / particle_count) * p + progress * TAU
			var particle_dist = explosion["range"] + progress * 50
			var particle_pos = exp_pos + Vector2(cos(angle), sin(angle)) * particle_dist
			draw_circle(particle_pos, 2, Color(1, 1 - progress * 0.5, 0, 1.0 - progress))

func reset_game():
	gold = 500
	lives = 20
	wave = 1
	walls_available = 10
	game_over = false
	enemies = []
	towers = []
	walls = []
	bullets = []
	explosions = []
	selected_mode = 1
	ui_buttons[0].button_pressed = true
	ui_buttons[1].button_pressed = false
	ui_buttons[2].button_pressed = false
	wave_in_progress = false
	total_enemies_in_wave = 0
	enemies_spawned = 0
	castle_shake_timer = 0.0
	castle_blink_timer = 0.0
	
	for child in get_children():
		if child.name != "UI" and not child is CanvasLayer:
			child.queue_free()
	
	castle_sprite = Sprite2D.new()
	castle_sprite.texture = castle_texture
	castle_sprite.position = castle_pos
	castle_sprite.scale = Vector2(1.5, 1.5)
	add_child(castle_sprite)
	
	queue_redraw()
	
	var label = get_node("UI/Label")
	label.text = "Gold:500 | Lives:20 | Walls:10 | Wave 1"
	label.add_theme_color_override("font_color", Color.WHITE)
	
	await get_tree().create_timer(0.5).timeout
	start_wave()
