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
var laser_beams = []
var game_over = false
var selected_mode = 1
var wave_in_progress = false
var total_enemies_in_wave = 0
var enemies_spawned = 0

var castle_pos = Vector2(450, 300)
var castle_sprite: Sprite2D
var castle_shake_timer = 0.0
var castle_shake_intensity = 0.0
var castle_blink_timer = 0.0

var wall_texture = preload("res://assets/images/wall.png")
var castle_texture = preload("res://assets/images/castle.png")

var tower_types = {
	1: {"name": "Basic",  "range": 120, "damage": 10, "shoot_speed": 1.0, "cost": 100, "color": Color.GREEN,      "explosion_range": 30,  "type": "normal"},
	2: {"name": "Sniper", "range": 180, "damage": 30, "shoot_speed": 2.0, "cost": 200, "color": Color.DARK_BLUE,  "explosion_range": 50,  "type": "normal"},
	3: {"name": "Gun",    "range": 80,  "damage": 5,  "shoot_speed": 0.3, "cost": 150, "color": Color.RED,        "explosion_range": 20,  "type": "normal"},
	4: {"name": "Freeze", "range": 150, "damage": 0,  "shoot_speed": 1.5, "cost": 180, "color": Color.CYAN,       "explosion_range": 60,  "type": "freeze", "freeze_time": 3.0, "slow_ratio": 0.3},
	5: {"name": "Laser",  "range": 160, "damage": 15, "shoot_speed": 0.1, "cost": 220, "color": Color.LIGHT_GRAY, "type": "laser"},
}

var enemy_types = {
	1: {"name": "Weak",   "hp": 20, "speed": 100.0, "color": Color.YELLOW, "reward": 10},
	2: {"name": "Normal", "hp": 40, "speed": 80.0,  "color": Color.WHITE,  "reward": 20},
	3: {"name": "Strong", "hp": 80, "speed": 60.0,  "color": Color.RED,    "reward": 50},
}

var ui_buttons = []
var dynamic_nodes = []

func _ready():
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
		"castle_hit": sound = load("res://assets/sounds/castle_hit.wav")
		"shoot":      sound = load("res://assets/sounds/shoot.wav")
		"explosion":  sound = load("res://assets/sounds/explosion.wav")
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

	var btns = [
		["GREEN\nBASIC\n100G", 1],
		["BLUE\nSNIPER\n200G", 2],
		["RED\nGUN\n150G", 3],
		["CYAN\nFREEZE\n180G", 4],
		["WHITE\nLASER\n220G", 5],
	]
	for btn_data in btns:
		var btn = Button.new()
		btn.text = btn_data[0]
		btn.toggle_mode = true
		btn.button_pressed = (btn_data[1] == 1)
		btn.custom_minimum_size = Vector2(0, 60)
		var mode = btn_data[1]
		btn.pressed.connect(func(): _on_weapon_selected(mode))
		hbox1.add_child(btn)
		ui_buttons.append(btn)

	var hbox2 = HBoxContainer.new()
	hbox2.add_theme_constant_override("separation", 5)
	vbox.add_child(hbox2)

	var wall_btn = Button.new()
	wall_btn.text = "WALL\nWALL\n1 PC"
	wall_btn.toggle_mode = true
	wall_btn.custom_minimum_size = Vector2(0, 60)
	wall_btn.pressed.connect(func(): _on_weapon_selected(6))
	hbox2.add_child(wall_btn)
	ui_buttons.append(wall_btn)

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
		if mouse_y > get_viewport_rect().size.y * 0.75:
			return
		var pos = get_global_mouse_position()
		match selected_mode:
			1, 2, 3, 4, 5:
				var info = tower_types[selected_mode]
				if gold >= info["cost"]:
					gold -= info["cost"]
					place_tower(pos, selected_mode)
					queue_redraw()
			6:
				if walls_available > 0:
					walls_available -= 1
					place_wall(pos)
					queue_redraw()

func place_tower(pos, tower_type):
	var info = tower_types[tower_type]
	var obj = ColorRect.new()
	obj.size = Vector2(16, 16)
	obj.position = pos - Vector2(8, 8)
	obj.color = info["color"]
	add_child(obj)
	dynamic_nodes.append(obj)
	towers.append({
		"pos": pos,
		"type": tower_type,
		"range": info["range"],
		"damage": info["damage"],
		"shoot_speed": info["shoot_speed"],
		"explosion_range": info.get("explosion_range", 0),
		"obj": obj,
		"shoot_timer": 0.0,
		"laser_target": null,
	})

func place_wall(pos):
	var obj = Sprite2D.new()
	obj.texture = wall_texture
	obj.position = pos
	add_child(obj)
	dynamic_nodes.append(obj)
	walls.append({
		"pos": pos,
		"obj": obj,
		"rect": Rect2(pos - Vector2(16, 16), Vector2(32, 32)),
		"hp": 3,
		"max_hp": 3,
	})

func start_wave():
	if wave_in_progress:
		return
	wave_in_progress = true
	var enemy_list = generate_wave_enemies()
	total_enemies_in_wave = enemy_list.size()
	enemies_spawned = 0
	walls_available += 5
	for enemy_type in enemy_list:
		await get_tree().create_timer(randf_range(0.2, 0.8)).timeout
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
	var list = []
	if wave == 1:
		for i in range(5): list.append(1)
	elif wave == 2:
		for i in range(3): list.append(1)
		for i in range(3): list.append(2)
	elif wave == 3:
		for i in range(2): list.append(1)
		for i in range(3): list.append(2)
		list.append(3)
	else:
		for i in range(2): list.append(1)
		for i in range(wave): list.append(2)
		for i in range(wave - 2): list.append(3)
	return list

func spawn_enemy(enemy_type: int):
	var info = enemy_types[enemy_type]
	var obj = Sprite2D.new()
	var tex = load("res://assets/images/cockroach.png")
	if tex:
		obj.texture = tex
	obj.scale = Vector2(1.5, 1.5)
	match enemy_type:
		1: obj.self_modulate = Color.YELLOW
		2: obj.self_modulate = Color.WHITE
		3: obj.self_modulate = Color.RED
	add_child(obj)
	dynamic_nodes.append(obj)
	var spawn_pos = get_random_edge_position()
	enemies.append({
		"type": enemy_type,
		"hp": info["hp"],
		"max_hp": info["hp"],
		"x": spawn_pos.x,
		"y": spawn_pos.y,
		"speed": info["speed"],
		"base_speed": info["speed"],   # 原始速度，緩速恢復用
		"reward": info["reward"],
		"obj": obj,
		"direction": Vector2.ZERO,
		"wall_collision_timer": 0.0,
		"redirect_timer": 0.0,
		"stuck_timer": 0.0,
		"last_pos": spawn_pos,
		"hit_wall_idx": -1,
		"freeze_timer": 0.0,           # 緩速剩餘時間
		"is_frozen": false,            # 是否被緩速中
	})
	enemies_spawned += 1

func get_random_edge_position() -> Vector2:
	var sw = get_viewport_rect().size.x
	var sh = get_viewport_rect().size.y
	match randi() % 4:
		0: return Vector2(randf_range(0, sw), 0)
		1: return Vector2(randf_range(0, sw * 0.8), sh * 0.8)
		2: return Vector2(0, randf_range(0, sh * 0.8))
		3: return Vector2(sw, randf_range(0, sh * 0.8))
	return Vector2.ZERO

# 對範圍內所有敵人套用緩速
func apply_freeze(pos: Vector2, radius: float, freeze_time: float, slow_ratio: float):
	for e in enemies:
		if not is_instance_valid(e["obj"]):
			continue
		var dist = pos.distance_to(Vector2(e["x"], e["y"]))
		if dist < radius:
			e["freeze_timer"] = freeze_time
			e["is_frozen"] = true
			e["speed"] = e["base_speed"] * slow_ratio  # 減速到原來的 30%
			if is_instance_valid(e["obj"]):
				e["obj"].self_modulate = Color.CYAN  # 變成藍色表示被凍結

func check_wall_collision(enemy_pos: Vector2, _dir: Vector2) -> int:
	var rect = Rect2(enemy_pos - Vector2(10, 10), Vector2(20, 20))
	for i in range(walls.size()):
		if rect.intersects(walls[i]["rect"]):
			return i
	return -1

func rotate_direction(dir: Vector2, deg: float) -> Vector2:
	var rad = deg_to_rad(deg)
	return Vector2(dir.x * cos(rad) - dir.y * sin(rad), dir.x * sin(rad) + dir.y * cos(rad)).normalized()

func get_turn_directions(dir: Vector2) -> Array:
	var result = []
	for a in [45.0, 90.0, 135.0, -45.0, -90.0, -135.0]:
		result.append(rotate_direction(dir, a))
	return result

func trigger_castle_damage():
	play_sound.call_deferred("castle_hit")
	castle_shake_timer = 0.3
	castle_shake_intensity = 8.0
	castle_blink_timer = 0.3

func _process(delta):
	if game_over:
		return

	var sw = get_viewport_rect().size.x
	var sh = get_viewport_rect().size.y

	castle_shake_timer -= delta
	castle_blink_timer -= delta
	if is_instance_valid(castle_sprite):
		castle_sprite.modulate = Color.WHITE
		if castle_blink_timer > 0:
			castle_sprite.modulate = Color.WHITE if int(castle_blink_timer * 10) % 2 == 0 else Color(1.2, 0.8, 0.8)
		var shake = Vector2.ZERO
		if castle_shake_timer > 0:
			shake = Vector2(randf_range(-castle_shake_intensity, castle_shake_intensity), randf_range(-castle_shake_intensity, castle_shake_intensity))
		castle_sprite.position = castle_pos + shake

	# 更新敵人（包含 freeze 計時器）
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if not is_instance_valid(e["obj"]):
			enemies.remove_at(i)
			continue

		# 更新緩速計時器
		if e["is_frozen"]:
			e["freeze_timer"] -= delta
			if e["freeze_timer"] <= 0:
				# 緩速結束，恢復原速
				e["is_frozen"] = false
				e["speed"] = e["base_speed"]
				# 恢復原本顏色
				match e["type"]:
					1: e["obj"].self_modulate = Color.YELLOW
					2: e["obj"].self_modulate = Color.WHITE
					3: e["obj"].self_modulate = Color.RED

		if e["direction"] == Vector2.ZERO:
			e["direction"] = (castle_pos - Vector2(e["x"], e["y"])).normalized()

		e["wall_collision_timer"] -= delta
		e["redirect_timer"] -= delta
		e["stuck_timer"] -= delta

		var next_pos = Vector2(e["x"], e["y"]) + e["direction"] * e["speed"] * delta

		if next_pos.x < -50 or next_pos.x > sw + 50 or next_pos.y < -50 or next_pos.y > sh * 0.8 + 50:
			e["direction"] = (castle_pos - Vector2(e["x"], e["y"])).normalized()
			e["redirect_timer"] = 1.0
			next_pos = Vector2(e["x"], e["y"]) + e["direction"] * e["speed"] * delta

		var wall_idx = check_wall_collision(next_pos, e["direction"])
		if wall_idx >= 0:
			if e["wall_collision_timer"] <= 0 and e["stuck_timer"] <= 0:
				if e["hit_wall_idx"] != wall_idx:
					walls[wall_idx]["hp"] -= 1
					e["hit_wall_idx"] = wall_idx
					if walls[wall_idx]["hp"] <= 0:
						if is_instance_valid(walls[wall_idx]["obj"]):
							walls[wall_idx]["obj"].queue_free()
						walls.remove_at(wall_idx)
				var turns = get_turn_directions(e["direction"])
				var avail = turns.filter(func(d): return check_wall_collision(Vector2(e["x"], e["y"]) + d * e["speed"] * delta, d) < 0)
				e["direction"] = avail[randi() % avail.size()] if avail.size() > 0 else turns[randi() % turns.size()]
				e["wall_collision_timer"] = 0.2
				e["stuck_timer"] = 0.4
				e["redirect_timer"] = 1.5
		else:
			e["hit_wall_idx"] = -1
			e["x"] = next_pos.x
			e["y"] = next_pos.y

		if e["redirect_timer"] <= 0:
			var to_castle = (castle_pos - Vector2(e["x"], e["y"])).normalized()
			if e["direction"].dot(to_castle) < 0.3:
				e["direction"] = to_castle

		e["obj"].position = Vector2(e["x"], e["y"]) - Vector2(8, 8)
		e["last_pos"] = Vector2(e["x"], e["y"])

		if e["hp"] <= 0:
			gold += e["reward"]
			if is_instance_valid(e["obj"]): e["obj"].queue_free()
			enemies.remove_at(i)
			continue

		if Vector2(e["x"], e["y"]).distance_to(castle_pos) < 60:
			lives -= 1
			trigger_castle_damage()
			if is_instance_valid(e["obj"]): e["obj"].queue_free()
			enemies.remove_at(i)
			if lives <= 0:
				game_over = true

	laser_beams.clear()

	# 更新塔
	for tower in towers:
		if not is_instance_valid(tower["obj"]):
			continue
		tower["shoot_timer"] -= delta

		var target = null
		var closest_dist = tower["range"]
		for e in enemies:
			if not is_instance_valid(e["obj"]):
				continue
			var dist = tower["pos"].distance_to(Vector2(e["x"], e["y"]))
			if dist < closest_dist:
				closest_dist = dist
				target = e

		if tower["type"] == 5:
			# 雷射塔
			tower["laser_target"] = target
			if target != null:
				if tower["shoot_timer"] <= 0:
					target["hp"] -= tower["damage"]
					tower["shoot_timer"] = tower["shoot_speed"]
				laser_beams.append({"from": tower["pos"], "to": Vector2(target["x"], target["y"])})
		else:
			# 一般塔 + Freeze 塔
			if tower["shoot_timer"] <= 0 and target:
				play_sound.call_deferred("shoot")
				var bullet_color = Color.YELLOW
				if tower["type"] == 4:
					bullet_color = Color.CYAN
				var bullet_obj = ColorRect.new()
				bullet_obj.size = Vector2(10, 10)
				bullet_obj.color = bullet_color
				add_child(bullet_obj)
				bullets.append({
					"pos": tower["pos"],
					"target_enemy": target,
					"speed": 350.0,
					"damage": tower["damage"],
					"explosion_range": tower["explosion_range"],
					"obj": bullet_obj,
					"lifetime": 5.0,
					"tower_type": tower["type"],      # 記錄塔的類型
					"freeze_time": tower_types[tower["type"]].get("freeze_time", 0.0),
					"slow_ratio": tower_types[tower["type"]].get("slow_ratio", 1.0),
				})
				tower["shoot_timer"] = tower["shoot_speed"]

	# 更新子彈
	for i in range(bullets.size() - 1, -1, -1):
		var b = bullets[i]
		if not is_instance_valid(b["obj"]):
			bullets.remove_at(i)
			continue
		b["lifetime"] -= delta
		if b["lifetime"] <= 0 or not b["target_enemy"] in enemies:
			if is_instance_valid(b["obj"]): b["obj"].queue_free()
			bullets.remove_at(i)
			continue
		var target_pos = Vector2(b["target_enemy"]["x"], b["target_enemy"]["y"])
		var dir = (target_pos - b["pos"]).normalized()
		b["pos"] += dir * b["speed"] * delta
		b["obj"].position = b["pos"] - Vector2(5, 5)
		if b["pos"].distance_to(target_pos) < 12:
			if b["tower_type"] == 4:
				# Freeze 子彈：套用範圍緩速
				apply_freeze(b["pos"], b["explosion_range"], b["freeze_time"], b["slow_ratio"])
				# 範圍冰凍視覺效果
				explosions.append({"pos": b["pos"], "range": b["explosion_range"], "lifetime": 0.4, "type": "freeze"})
			else:
				create_explosion(b["pos"], b["explosion_range"], b["damage"])
			if is_instance_valid(b["obj"]): b["obj"].queue_free()
			bullets.remove_at(i)

	for i in range(explosions.size() - 1, -1, -1):
		explosions[i]["lifetime"] -= delta
		if explosions[i]["lifetime"] <= 0:
			explosions.remove_at(i)

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
	explosions.append({"pos": pos, "range": explosion_range, "lifetime": 0.3, "type": "normal"})
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if pos.distance_to(Vector2(e["x"], e["y"])) < explosion_range:
			e["hp"] -= damage
			if e["hp"] <= 0:
				gold += e["reward"]
				if is_instance_valid(e["obj"]): e["obj"].queue_free()
				enemies.remove_at(i)

func _draw():
	for tower in towers:
		if not is_instance_valid(tower["obj"]):
			continue
		var range_color = Color(1, 1, 1, 0.08)
		var arc_color = Color(1, 1, 1, 0.25)
		if tower["type"] == 4:
			range_color = Color(0, 1, 1, 0.08)
			arc_color = Color(0, 1, 1, 0.3)
		elif tower["type"] == 5:
			range_color = Color(1, 0.5, 0, 0.08)
			arc_color = Color(1, 0.5, 0, 0.3)
		draw_circle(tower["pos"], tower["range"], range_color)
		draw_arc(tower["pos"], tower["range"], 0, TAU, 32, arc_color, 1.0)

	for beam in laser_beams:
		draw_line(beam["from"], beam["to"], Color(1, 0.3, 0, 0.9), 3.0)
		draw_line(beam["from"], beam["to"], Color(1, 0.8, 0.5, 0.5), 1.0)
		draw_circle(beam["to"], 6, Color(1, 0.5, 0, 0.8))

	for e in enemies:
		if not is_instance_valid(e["obj"]):
			continue
		var ep = Vector2(e["x"], e["y"])
		draw_rect(Rect2(ep.x - 16, ep.y - 30, 24, 4), Color.BLACK)
		var ratio = float(e["hp"]) / float(e["max_hp"])
		draw_rect(Rect2(ep.x - 16, ep.y - 30, 24 * ratio, 4), Color.GREEN.lerp(Color.RED, 1.0 - ratio))
		draw_rect(Rect2(ep.x - 16, ep.y - 30, 24, 4), Color.WHITE, false, 1.0)
		# 緩速時顯示冰晶效果
		if e["is_frozen"]:
			draw_arc(ep, 14, 0, TAU, 8, Color(0, 1, 1, 0.6), 2.0)

	for wall in walls:
		if not is_instance_valid(wall["obj"]):
			continue
		var ratio = float(wall["hp"]) / float(wall["max_hp"])
		draw_rect(Rect2(wall["pos"].x - 12, wall["pos"].y + 20, 24, 2), Color.BLACK)
		draw_rect(Rect2(wall["pos"].x - 12, wall["pos"].y + 20, 24 * ratio, 2), Color.CYAN.lerp(Color.RED, 1.0 - ratio))

	for exp in explosions:
		var p = 1.0 - (exp["lifetime"] / (0.4 if exp.get("type", "normal") == "freeze" else 0.3))
		if exp.get("type", "normal") == "freeze":
			# 冰凍爆炸：藍色
			draw_circle(exp["pos"], exp["range"] * (1.0 + p * 0.3), Color(0, 0.8, 1, 0.4 * (1.0 - p)))
			draw_circle(exp["pos"], exp["range"] * 0.7, Color(0.5, 1, 1, 0.6 * (1.0 - p)))
			draw_arc(exp["pos"], exp["range"], 0, TAU, 32, Color(0, 1, 1, 0.8 * (1.0 - p)), 2.0)
		else:
			# 一般爆炸：橙色
			draw_circle(exp["pos"], exp["range"] * (1.0 + p * 0.5), Color(1, 1, 0, 0.4 * (1.0 - p)))
			draw_circle(exp["pos"], exp["range"] * 0.8, Color(1, 0.6, 0, 0.6 * (1.0 - p)))
			draw_circle(exp["pos"], exp["range"] * 0.4, Color(1, 0.2, 0, 1.0 * (1.0 - p)))

func reset_game():
	game_over = true
	wave_in_progress = false

	for e in enemies:
		if is_instance_valid(e["obj"]): e["obj"].queue_free()
	for t in towers:
		if is_instance_valid(t["obj"]): t["obj"].queue_free()
	for w in walls:
		if is_instance_valid(w["obj"]): w["obj"].queue_free()
	for b in bullets:
		if is_instance_valid(b["obj"]): b["obj"].queue_free()
	if is_instance_valid(castle_sprite):
		castle_sprite.queue_free()

	enemies.clear()
	towers.clear()
	walls.clear()
	bullets.clear()
	explosions.clear()
	laser_beams.clear()
	dynamic_nodes.clear()

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

	await get_tree().process_frame

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
