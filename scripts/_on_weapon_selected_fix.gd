func _on_weapon_selected(mode: int):
	selected_mode = mode
	print("Mode selected: %d" % mode)
	for btn in ui_buttons:
		btn.button_pressed = false
	# 根據 mode 設置按鈕
	match mode:
		1: ui_buttons[0].button_pressed = true  # BASIC
		2: ui_buttons[1].button_pressed = true  # SNIPER
		3: ui_buttons[2].button_pressed = true  # GUN (if it exists)
		4: ui_buttons[3].button_pressed = true  # FREEZE
		5: ui_buttons[4].button_pressed = true  # LASER
