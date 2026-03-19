extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBarPanel/HealthBar
@onready var health_label = $MarginContainer/VBoxContainer/HealthBarPanel/HealthLabel

func _ready():
	# Find player and connect to health signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(current_health: int, max_health: int):
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = str(current_health) + " / " + str(max_health)

	# Change color based on health percentage
	var health_percent = float(current_health) / float(max_health)
	if health_percent <= 0.25:
		health_bar.modulate = Color(1, 0, 0)  # Red
	elif health_percent <= 0.5:
		health_bar.modulate = Color(1, 0.5, 0)  # Orange
	else:
		health_bar.modulate = Color(0, 1, 0)  # Green
