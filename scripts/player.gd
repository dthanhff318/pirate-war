extends CharacterBody2D

# Movement settings
const SPEED = 200.0
const JUMP_VELOCITY = -400.0

# Gravity (get from project settings)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Jump state tracking
var is_jumping = false
var was_on_floor = false

# Knockback state
var knockback_velocity = Vector2.ZERO
var knockback_timer = 0.0
const KNOCKBACK_DURATION = 0.3  # How long knockback lasts

# Bomb spawning
@export var bomb_scene: PackedScene  # Drag bomb.tscn here in Inspector
const BOMB_SPAWN_OFFSET = Vector2(0, 0)  # Spawn bomb in front of player

# Virtual joystick reference
var joystick: Control = null

func _ready():
	# Find joystick in scene tree
	joystick = get_tree().get_first_node_in_group("virtual_joystick")

func _physics_process(delta):
	# Track floor state
	var currently_on_floor = is_on_floor()

	# Get input direction from keyboard OR joystick
	var direction = get_movement_direction()

	# Handle knockback timer
	if knockback_timer > 0:
		knockback_timer -= delta
		# During knockback, use knockback velocity
		velocity = knockback_velocity
		# Apply gravity to knockback for parabolic motion
		if not currently_on_floor:
			velocity.y += gravity * delta
			knockback_velocity = velocity  # Update stored velocity
	else:
		# Normal movement when not in knockback
		# Add gravity
		if not currently_on_floor:
			velocity.y += gravity * delta
		else:
			# Reset jump state when landing
			is_jumping = false

		# Handle jump with anticipation
		if Input.is_action_just_pressed("ui_accept") and currently_on_floor:
			# Play anticipation animation briefly
			play_animation("jump_anticipation")
			# Small delay for anticipation (optional - comment out if too slow)
			# await get_tree().create_timer(0.1).timeout
			velocity.y = JUMP_VELOCITY
			is_jumping = true

		# Handle bomb spawning (Q key)
		if Input.is_action_just_pressed("throw_bomb"):  # Q key - configure in Project Settings → Input Map
			spawn_bomb()

		# Apply horizontal movement
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Update animation
	update_animation(direction, currently_on_floor)

	# Update floor state for next frame
	was_on_floor = currently_on_floor

	# Apply movement
	move_and_slide()

func update_animation(direction, on_floor):
	# Flip sprite when changing direction
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true

	# Select animation based on state
	if not on_floor:
		# In the air - 3 phases of jump
		if velocity.y < -50:
			# Phase 2: Going up (jumping) - negative velocity
			play_animation("jump")
		elif velocity.y > 50:
			# Phase 3: Falling down - positive velocity
			play_animation("fall")
		else:
			# At the peak - transition moment between jump and fall
			# Keep using jump animation for smooth transition
			play_animation("jump")
	else:
		# On ground
		if direction != 0:
			# Moving - play run animation
			play_animation("run")
		else:
			# Standing still - play idle
			play_animation("idle")

func play_animation(anim_name):
	# Only play if animation exists and is not already playing
	if $AnimatedSprite2D.sprite_frames.has_animation(anim_name):
		if $AnimatedSprite2D.animation != anim_name:
			$AnimatedSprite2D.play(anim_name)
	else:
		# Fallback to idle if animation doesn't exist
		if $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")

func spawn_bomb():
	# Check if bomb scene is assigned
	if bomb_scene == null:
		push_warning("Bomb scene not assigned! Drag bomb.tscn to Player in Inspector")
		return

	# Create bomb instance
	var bomb = bomb_scene.instantiate()

	# Set bomb position at same position as player
	bomb.global_position = global_position

	# Add bomb to scene (same parent as player)
	get_parent().add_child(bomb)

func apply_knockback(knockback: Vector2):
	# Called by bomb explosion
	knockback_velocity = velocity + knockback
	knockback_timer = KNOCKBACK_DURATION

func get_movement_direction() -> float:
	# Get input from keyboard or joystick
	var keyboard_input = Input.get_axis("ui_left", "ui_right")

	# If joystick exists and is being used, use it
	if joystick and joystick.get_direction().length() > 0:
		return joystick.get_direction().x

	# Otherwise use keyboard
	return keyboard_input
