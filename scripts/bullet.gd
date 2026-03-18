extends Area2D

var speed: float = 300.0
var target: Node2D
var damage: int = 10
var traveled_distance: float = 0.0
var max_distance: float = 500.0

func _ready():
	$Sprite2D.color = Color.YELLOW

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		traveled_distance += speed * delta
		
		if global_position.distance_to(target.global_position) < 10:
			hit(target)
	else:
		queue_free()
	
	if traveled_distance > max_distance:
		queue_free()

func hit(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	queue_free()
