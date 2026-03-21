extends Control

func _ready():
	# Connect signals của tất cả buttons
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Chuyển sang gameplay scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed():
	# Placeholder cho settings menu (sẽ implement sau)
	print("Settings clicked - Coming soon!")

func _on_quit_pressed():
	# Thoát game
	get_tree().quit()
