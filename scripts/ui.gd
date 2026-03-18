extends CanvasLayer

# 這是手機 UI 層 - 包含武器選擇和重置按鈕

func _ready():
	# 建立垂直佈局
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 0.5
	vbox.offset_top = 10
	vbox.offset_left = 10
	add_child(vbox)
	
	# 標題
	var title = Label.new()
	title.text = "選擇武器"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# 武器選擇 RadioButton 組
	var radio_group = []
	
	# 基礎塔 (Tower 1)
	var radio1 = CheckBox.new()
	radio1.button_pressed = true
	radio1.text = "🟢 基礎塔 (100 金)"
	radio1.custom_minimum_size = Vector2(200, 40)
	radio1.toggled.connect(_on_tower_selected.bindv([1, radio_group]))
	radio_group.append(radio1)
	vbox.add_child(radio1)
	
	# 牆 (Wall)
	var radio2 = CheckBox.new()
	radio2.text = "🧱 牆 (1 牆數)"
	radio2.custom_minimum_size = Vector2(200, 40)
	radio2.toggled.connect(_on_tower_selected.bindv([2, radio_group]))
	radio_group.append(radio2)
	vbox.add_child(radio2)
	
	# 狙擊塔 (Tower 2)
	var radio3 = CheckBox.new()
	radio3.text = "🔵 狙擊塔 (200 金)"
	radio3.custom_minimum_size = Vector2(200, 40)
	radio3.toggled.connect(_on_tower_selected.bindv([3, radio_group]))
	radio_group.append(radio3)
	vbox.add_child(radio3)
	
	# 間隔
	vbox.add_child(Control.new())
	
	# 重置按鈕
	var reset_btn = Button.new()
	reset_btn.text = "🔄 重置遊戲"
	reset_btn.custom_minimum_size = Vector2(200, 50)
	reset_btn.add_theme_font_size_override("font_size", 20)
	reset_btn.pressed.connect(_on_reset_pressed)
	vbox.add_child(reset_btn)

func _on_tower_selected(pressed: bool, tower_type: int, radio_group: Array):
	if pressed:
		# 取消其他的選擇
		for i in range(radio_group.size()):
			if i + 1 != tower_type:
				radio_group[i].button_pressed = false
		
		# 通知主遊戲改變武器
		var game = get_tree().root.get_child(0)
		if game and game.has_method("set_selected_mode"):
			game.set_selected_mode(tower_type)

func _on_reset_pressed():
	var game = get_tree().root.get_child(0)
	if game and game.has_method("reset_game"):
		game.reset_game()
