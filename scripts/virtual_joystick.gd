extends Control

# Joystick properties
@export var max_distance = 50.0  # Max distance stick can move from center
@export var deadzone = 0.2  # Ignore small movements below this threshold

# Nodes
@onready var base = $Base  # Background circle
@onready var stick = $Base/Stick  # Draggable stick

# State
var is_pressed = false
var stick_center = Vector2.ZERO
var output = Vector2.ZERO  # Output direction (-1 to 1 for both x and y)

func _ready():
	# Store the center position of the base
	stick_center = base.size / 2

func _process(_delta):
	if not is_pressed:
		# Return stick to center smoothly
		stick.position = stick.position.lerp(stick_center, 0.2)

		# Update output
		var direction = (stick.position - stick_center) / max_distance
		if direction.length() < deadzone:
			output = Vector2.ZERO
		else:
			output = direction.normalized() * ((direction.length() - deadzone) / (1 - deadzone))

func _input(event):
	# Handle touch input
	if event is InputEventScreenTouch:
		var touch_pos = event.position - global_position

		if event.pressed:
			# Check if touch is on the joystick base
			if is_point_inside_base(touch_pos):
				is_pressed = true
				update_stick_position(touch_pos)
		else:
			is_pressed = false

	elif event is InputEventScreenDrag and is_pressed:
		var touch_pos = event.position - global_position
		update_stick_position(touch_pos)

func is_point_inside_base(point: Vector2) -> bool:
	# Check if point is inside the base circle
	var distance = (point - stick_center).length()
	return distance < max_distance * 1.5  # 1.5x for easier touch

func update_stick_position(touch_pos: Vector2):
	# Calculate stick position relative to center
	var direction = touch_pos - stick_center

	# Clamp to max_distance
	if direction.length() > max_distance:
		direction = direction.normalized() * max_distance

	stick.position = stick_center + direction

	# Calculate output (-1 to 1)
	var normalized_direction = direction / max_distance

	# Apply deadzone
	if normalized_direction.length() < deadzone:
		output = Vector2.ZERO
	else:
		output = normalized_direction.normalized() * ((normalized_direction.length() - deadzone) / (1 - deadzone))

func get_direction() -> Vector2:
	# Public method to get joystick direction
	return output
