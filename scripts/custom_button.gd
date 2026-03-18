# CustomButton.gd - 自訂按鈕，支援 draw_string

extends Control

class_name CustomButton

var is_pressed = false
var text = ""
var selected = false
var pressed = Signal()

func _ready():
	mouse_entered.connect(func(): queue_redraw())
	mouse_exited.connect(func(): queue_redraw())

func _input_event(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = true
		selected = !selected
		pressed.emit()
		queue_redraw()

func _draw():
	var bg_color = Color.DARK_SLATE_GRAY if selected else Color.SLATE_GRAY
	var border_color = Color.YELLOW if selected else Color.WHITE
	
	if is_mouse_over():
		bg_color = bg_color.lightened(0.2)
	
	# 背景
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	
	# 邊框
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 2.0)
	
	# 文字
	var font = get_theme_font("font") or ThemeDB.fallback_font
	var font_size = get_theme_font_size("font_size") or 14
	
	var text_lines = text.split("\n")
	var line_height = font_size + 5
	var total_height = line_height * text_lines.size()
	var start_y = (size.y - total_height) / 2.0
	
	for i in range(text_lines.size()):
		var line = text_lines[i]
		var line_y = start_y + i * line_height
		
		# 計算文字寬度以置中
		var text_size = font.get_string_size(line, 0, -1, font_size)
		var text_x = (size.x - text_size.x) / 2.0
		
		draw_string(font, Vector2(text_x, line_y + font_size), line, 0, -1, font_size, Color.WHITE)

func set_pressed(value: bool):
	selected = value
	queue_redraw()

func get_pressed() -> bool:
	return selected
