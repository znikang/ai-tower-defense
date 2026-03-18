extends Node2D

var gold: int = 500
var lives: int = 20
var wave: int = 1
var game_over: bool = false
var tower_cost: int = 100
var enemies: Array = []
var towers: Array = []
var wave_in_progress: bool = false

@onready var ui = $UI
@onready var path = $Path2D

signal gold_changed(amount)
signal lives_changed(amount)
signal wave_changed(number)

func _ready():
	set_process_input(true)
	update_ui()
	start_wave()

func _input(event: InputEvent) -> void:
	if game_over:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		place_tower(mouse_pos)

func update_ui() -> void:
	if ui:
		ui.update_stats(gold, lives, wave)

func place_tower(pos: Vector2) -> void:
	if gold >= tower_cost:
		gold -= tower_cost
		emit_signal("gold_changed", gold)
		
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
	wave_changed.emit(wave)
	
	var enemy_count = 3 + wave
	for i in range(enemy_count):
		await get_tree().create_timer(0.5).timeout
		spawn_enemy()
	
	wave_in_progress = false

func spawn_enemy() -> void:
	var enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.game_manager = self
	path.add_child(enemy)
	enemies.append(enemy)

func enemy_reached_end(enemy: Node2D) -> void:
	lives -= 1
	lives_changed.emit(lives)
	enemies.erase(enemy)
	enemy.queue_free()
	update_ui()
	
	if lives <= 0:
		end_game()
	elif enemies.is_empty() and !wave_in_progress:
		wave += 1
		await get_tree().create_timer(1.0).timeout
		start_wave()

func enemy_died(enemy: Node2D) -> void:
	gold += 20
	gold_changed.emit(gold)
	enemies.erase(enemy)
	enemy.queue_free()
	update_ui()
	
	if enemies.is_empty() and !wave_in_progress:
		wave += 1
		await get_tree().create_timer(1.0).timeout
		start_wave()

func create_bullet(tower: Node2D, target: Node2D) -> void:
	var bullet = preload("res://scenes/bullet.tscn").instantiate()
	bullet.position = tower.position
	bullet.target = target
	add_child(bullet)

func end_game() -> void:
	game_over = true
	if ui:
		ui.show_game_over()
