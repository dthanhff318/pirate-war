extends CanvasLayer

@onready var health_bar = $Control/HPMarginContainer/NinePatchRect/HPBar

func _ready():
	# Find player and connect to health signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(current_health: int, max_health: int):
	# Update TextureProgressBar value (0-100)
	health_bar.max_value = max_health
	health_bar.value = current_health
