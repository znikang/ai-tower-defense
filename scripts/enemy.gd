extends Node2D

var speed: float = 150.0
var max_hp: int = 30
var hp: int = 30
var game_manager: Node2D
var progress: float = 0.0
var path_curve: Curve2D

func _ready():
	$Sprite2D.color = Color.LIGHT_BLUE
	# 從遊戲管理器獲取路徑
	var path = get_parent().get_node("Path2D")
	if path:
		path_curve = path.curve

func _process(delta: float) -> void:
	if path_curve:
		var path_length = path_curve.get_baked_length()
		progress += speed * delta
		
		# 敵人到達終點
		if progress >= path_length:
			if game_manager:
				game_manager.enemy_reached_end(self)
			queue_free()
			return
		
		# 沿著路徑移動
		global_position = path_curve.sample_baked(progress)

func take_damage(damage: int) -> void:
	hp -= damage
	$Sprite2D.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color.WHITE
	
	if hp <= 0:
		die()

func die() -> void:
	if game_manager:
		game_manager.enemy_died(self)
	queue_free()
