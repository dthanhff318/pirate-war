extends CharacterBody2D

# Movement settings
const SPEED = 80.0
const PATROL_DISTANCE = 200.0  # How far to patrol before turning around

# Gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Patrol state
var direction = -1  # -1 = left, 1 = right
var start_position = Vector2.ZERO

func _ready():
	# Save starting position to calculate patrol range
	start_position = global_position

	# Start playing idle animation
	if $AnimatedSprite2D.sprite_frames.has_animation("idle"):
		$AnimatedSprite2D.play("idle")

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Patrol movement
	patrol()

	# Update animation
	update_animation()

	# Apply movement
	move_and_slide()

func patrol():
	# Move in current direction
	velocity.x = direction * SPEED

	# Calculate distance traveled from start position
	var distance_traveled = abs(global_position.x - start_position.x)

	# Turn around if traveled too far or hit a wall
	if distance_traveled >= PATROL_DISTANCE or is_on_wall():
		direction *= -1
		# Reset start position when turning around
		start_position = global_position
		# Flip sprite to face movement direction
		$AnimatedSprite2D.flip_h = direction > 0

func update_animation():
	# Currently only has idle animation, can add run later
	if $AnimatedSprite2D.sprite_frames.has_animation("idle"):
		if $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")
