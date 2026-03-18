extends Node2D

var gold: int = 500
var lives: int = 20
var wave: int = 1
var game_over: bool = false
var tower_cost: int = 100
var enemies: Array = []
var towers: Array = []
var wave_in_progress: bool = falsePath2D

@onready var ui = $UI
@onready var path = $

func _ready():
	print("遊戲開始！")
	print("Path2D 曲線長度: ", path.curve.get_baked_length())
	update_ui()
	await get_tree().create_timer(1.0).timeout
	start_wave()

func _input(event: InputEvent) -> void:
	if game_over:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		print("點擊位置: ", mouse_pos)
		place_tower(mouse_pos)

func update_ui() -> void:
	if ui:
		ui.update_stats(gold, lives, wave)

func place_tower(pos: Vector2) -> void:
	if gold >= tower_cost:
		gold -= tower_cost
		print("放置塔，剩餘金幣: ", gold)
		
		var tower = preload("res://scenes/tower.tscn").instantiate()
		tower.position = pos
		tower.game_manager = self
		add_child(tower)
		towers.append(tower)
		update_ui()

func start_wave() -> void:
	if wave_in_progress:
		return
	
	wave_in_progress = true
	print("第 %d 波開始" % wave)
	
	var enemy_count = 3 + wave
	for i in range(enemy_count):
		await get_tree().create_timer(1.0).timeout
		spawn_enemy()
	
	wave_in_progress = false

func spawn_enemy() -> void:
	print("生成敵人...")
	
	# 直接建立敵人，沒有腳本
	var enemy = Node2D.new()
	enemy.name = "Enemy"
	
	# 添加視覺效果（更大）
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.LIGHT_BLUE
	enemy.add_child(sprite)
	
	add_child(enemy)
	enemies.append(enemy)
	print("敵人生成！總敵人數: ", enemies.size(), " 位置: ", enemy.position)

func _process(_delta: float) -> void:
	# 更新所有敵人位置
	if path and path.curve:
		var path_length = path.curve.get_baked_length()
		print("Path 長度: ", path_length)
		
		for enemy in enemies:
			if not is_instance_valid(enemy):
				enemies.erase(enemy)
				continue
			
			if not enemy.has_meta("progress"):
				enemy.set_meta("progress", 0.0)
				print("敵人初始位置設定")
			
			var progress = enemy.get_meta("progress") as float
			progress += 50.0 * _delta  # 速度減半
			enemy.set_meta("progress", progress)
			
			if progress >= path_length:
				print("敵人到達終點！Progress: ", progress, " / ", path_length)
				enemy_reached_end(enemy)
			else:
				var new_pos = path.curve.sample_baked(progress)
				enemy.global_position = new_pos
				print("敵人位置: ", new_pos)

func enemy_reached_end(enemy: Node2D) -> void:
	print("敵人逃脫！")
	lives -= 1
	enemies.erase(enemy)
	enemy.queue_free()
	update_ui()
	
	if lives <= 0:
		end_game()

func create_bullet(tower: Node2D, target: Node2D) -> void:
	var bullet = preload("res://scenes/bullet.tscn").instantiate()
	bullet.position = tower.position
	bullet.target = target
	add_child(bullet)

func end_game() -> void:
	game_over = true
	print("遊戲結束！")
	if ui:
		ui.show_game_over()
