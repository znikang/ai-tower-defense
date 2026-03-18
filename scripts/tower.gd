extends Area2D

var tower_range: float = 150.0
var attack_speed: float = 1.0
var damage: int = 10
var target: Node2D = null
var can_shoot: bool = true
var game_manager: Node2D

@onready var range_circle = $RangeCircle
@onready var sprite = $Sprite2D

func _ready():
	range_circle.scale = Vector2.ONE * (tower_range * 2 / 32)
	sprite.color = Color.LIGHT_GREEN
	# 移除重複的信號連接

func _process(_delta: float) -> void:
	if target and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= tower_range:
			if can_shoot:
				shoot(target)
		else:
			target = null
	else:
		target = find_closest_enemy()

func find_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_distance: float = tower_range
	
	if game_manager and game_manager.enemies:
		for enemy in game_manager.enemies:
			if is_instance_valid(enemy):
				var distance = global_position.distance_to(enemy.global_position)
				if distance < closest_distance:
					closest = enemy
					closest_distance = distance
	
	return closest

func shoot(enemy: Node2D) -> void:
	if game_manager and is_instance_valid(enemy):
		can_shoot = false
		game_manager.create_bullet(self, enemy)
		await get_tree().create_timer(attack_speed).timeout
		can_shoot = true
