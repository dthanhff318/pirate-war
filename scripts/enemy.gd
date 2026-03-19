extends CharacterBody2D

# Movement settings
const SPEED = 80.0
const PATROL_DISTANCE = 300.0  # How far to patrol before turning around
const IDLE_PAUSE_TIME = 2.0  # How long to idle at patrol edges (in seconds)

# Gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Patrol state
var direction = -1  # -1 = left, 1 = right
var start_position = Vector2.ZERO
var is_paused = false  # Whether enemy is pausing at patrol edge
var pause_timer = 0.0  # Timer for idle pause

func _ready():
	# Save starting position to calculate patrol range
	start_position = global_position

	# Set initial sprite direction to match movement
	$AnimatedSprite2D.flip_h = direction < 0

	# Start playing run animation
	if $AnimatedSprite2D.sprite_frames.has_animation("run"):
		$AnimatedSprite2D.play("run")

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle pause timer
	if is_paused:
		pause_timer -= delta
		velocity.x = 0  # Stop moving during pause

		if pause_timer <= 0:
			# Pause finished, resume patrol
			is_paused = false
			direction *= -1  # Turn around
			# Flip sprite to face new movement direction
			$AnimatedSprite2D.flip_h = direction < 0
			# Reset start position for new patrol direction
			start_position = global_position
			# Play run animation
			if $AnimatedSprite2D.sprite_frames.has_animation("run"):
				$AnimatedSprite2D.play("run")
	else:
		# Patrol movement
		patrol()

	# Apply movement
	move_and_slide()

func patrol():
	# Move in current direction
	velocity.x = direction * SPEED

	# Calculate distance traveled from start position
	var distance_traveled = abs(global_position.x - start_position.x)

	# Pause at patrol edge or when hitting a wall
	if distance_traveled >= PATROL_DISTANCE or is_on_wall():
		is_paused = true
		pause_timer = IDLE_PAUSE_TIME
		# Play idle animation
		if $AnimatedSprite2D.sprite_frames.has_animation("idle"):
			$AnimatedSprite2D.play("idle")
