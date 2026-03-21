extends CharacterBody2D

# ========================================
# STATE MACHINE
# ========================================
enum PlayerState {
	IDLE,      # Standing still
	RUNNING,   # Moving horizontally
	JUMPING,   # Going up in air
	FALLING,   # Going down in air
	HIT,       # Taking damage (temporary invincibility)
	DEAD       # Game over
}

var current_state: PlayerState = PlayerState.IDLE

# ========================================
# HEALTH SYSTEM
# ========================================
signal health_changed(new_health, max_health)
@export var max_health: int = 100
var current_health: int = 100

# Movement settings
const SPEED = 200.0
const JUMP_VELOCITY = -500.0

# Gravity (get from project settings)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Knockback state (used in HIT state)
var knockback_velocity = Vector2.ZERO
var knockback_timer = 0.0
const KNOCKBACK_DURATION = 0.3  # How long knockback lasts

# Hit animation state (used in HIT state)
var hit_timer = 0.0
const HIT_ANIMATION_DURATION = 0.3  # Duration of hit animation

# Bomb spawning
@export var bomb_scene: PackedScene  # Drag bomb.tscn here in Inspector
const BOMB_SPAWN_OFFSET = Vector2(0, 0)  # Spawn bomb in front of player

# Virtual joystick reference
var joystick: Node2D = null

func _ready():
	# Find joystick in scene tree
	joystick = get_tree().get_first_node_in_group("virtual_joystick")
	# Emit initial health
	health_changed.emit(current_health, max_health)

# ========================================
# STATE MACHINE - Change State
# ========================================
func change_state(new_state: PlayerState) -> void:
	# Skip if already in this state
	if current_state == new_state:
		return

	# Debug: Print state transitions (helpful for debugging)
	# print("State: %s -> %s" % [PlayerState.keys()[current_state], PlayerState.keys()[new_state]])

	# Exit current state (cleanup)
	_exit_state(current_state)

	# Update state
	current_state = new_state

	# Enter new state (initialization)
	_enter_state(new_state)

func _enter_state(state: PlayerState) -> void:
	# Called when entering a new state
	match state:
		PlayerState.IDLE:
			play_animation("idle")
		PlayerState.RUNNING:
			play_animation("run")
		PlayerState.JUMPING:
			play_animation("jump")
		PlayerState.FALLING:
			play_animation("fall")
		PlayerState.HIT:
			play_animation("hit")
			hit_timer = HIT_ANIMATION_DURATION
		PlayerState.DEAD:
			play_animation("dead")  # You'll need to create this animation
			# Disable player controls
			set_physics_process(false)

func _exit_state(state: PlayerState) -> void:
	# Called when leaving a state (cleanup)
	match state:
		PlayerState.HIT:
			# No cleanup needed for HIT state
			pass
		PlayerState.DEAD:
			pass  # No cleanup needed
		_:
			pass  # Most states don't need cleanup

# ========================================
# STATE MACHINE - State Processors
# ========================================

func process_idle_state(delta: float, direction: float, on_floor: bool) -> void:
	# Apply gravity
	if not on_floor:
		velocity.y += gravity * delta
		# If falling, change to FALLING state
		if velocity.y > 0:  # Any positive velocity = falling
			change_state(PlayerState.FALLING)
		return

	# Decelerate horizontal movement
	velocity.x = move_toward(velocity.x, 0, SPEED)

	# Check for state transitions
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		change_state(PlayerState.JUMPING)
	elif direction != 0:
		change_state(PlayerState.RUNNING)

func process_running_state(delta: float, direction: float, on_floor: bool) -> void:
	# Apply gravity
	if not on_floor:
		velocity.y += gravity * delta
		# If falling, change to FALLING state
		if velocity.y > 0:  # Any positive velocity = falling
			change_state(PlayerState.FALLING)
		return

	# Apply horizontal movement
	velocity.x = direction * SPEED

	# Check for state transitions
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		change_state(PlayerState.JUMPING)
	elif direction == 0:
		change_state(PlayerState.IDLE)

func process_jumping_state(delta: float, direction: float, on_floor: bool) -> void:
	# Apply gravity
	velocity.y += gravity * delta

	# Apply horizontal movement (air control)
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.5)  # Slower deceleration in air

	# Check for state transitions
	if on_floor:
		# Landed
		if direction != 0:
			change_state(PlayerState.RUNNING)
		else:
			change_state(PlayerState.IDLE)
	elif velocity.y > 0:  # Any positive velocity = started falling
		change_state(PlayerState.FALLING)

func process_falling_state(delta: float, direction: float, on_floor: bool) -> void:
	# Apply gravity
	velocity.y += gravity * delta

	# Apply horizontal movement (air control)
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.5)  # Slower deceleration in air

	# Check for state transitions
	if on_floor:
		# Landed
		if direction != 0:
			change_state(PlayerState.RUNNING)
		else:
			change_state(PlayerState.IDLE)

func process_hit_state(delta: float, direction: float, on_floor: bool) -> void:
	# Apply gravity
	if not on_floor:
		velocity.y += gravity * delta

	# Apply knockback (if any)
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
		# Update knockback with gravity
		if not on_floor:
			knockback_velocity.y += gravity * delta
	else:
		# No knockback, allow slight movement
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * SPEED * 0.3, SPEED * 0.5)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Update hit timer
	hit_timer -= delta
	if hit_timer <= 0:
		# Hit animation finished, return to normal state
		if on_floor:
			if direction != 0:
				change_state(PlayerState.RUNNING)
			else:
				change_state(PlayerState.IDLE)
		else:
			if velocity.y > 0:  # Falling
				change_state(PlayerState.FALLING)
			else:  # Still going up
				change_state(PlayerState.JUMPING)

func process_dead_state(delta: float) -> void:
	# Apply gravity (body falls)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Stop all movement when on ground
		velocity.x = 0
		velocity.y = 0

	# No state transitions from DEAD (game over)

func _physics_process(delta):
	# Get input and floor state (needed by all states)
	var direction = get_movement_direction()
	var on_floor = is_on_floor()

	# Handle bomb spawning (works in all states except DEAD)
	if Input.is_action_just_pressed("throw_bomb") and current_state != PlayerState.DEAD:
		spawn_bomb()

	# Process current state
	match current_state:
		PlayerState.IDLE:
			process_idle_state(delta, direction, on_floor)
		PlayerState.RUNNING:
			process_running_state(delta, direction, on_floor)
		PlayerState.JUMPING:
			process_jumping_state(delta, direction, on_floor)
		PlayerState.FALLING:
			process_falling_state(delta, direction, on_floor)
		PlayerState.HIT:
			process_hit_state(delta, direction, on_floor)
		PlayerState.DEAD:
			process_dead_state(delta)

	# Apply movement
	move_and_slide()

	# Flip sprite based on movement direction
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true

# Removed update_animation() - now handled by state machine's _enter_state()

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
	if joystick and joystick.get_value().length() > 0:
		return joystick.get_value().x

	# Otherwise use keyboard
	return keyboard_input


func _on_virtual_joystick_analogic_change(move: Vector2) -> void:
	velocity = move

# ========================================
# HEALTH MANAGEMENT
# ========================================
func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)

	# Change to HIT state (unless already dead)
	if current_state != PlayerState.DEAD:
		change_state(PlayerState.HIT)

	# Check for death
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die():
	print("Player died!")
	change_state(PlayerState.DEAD)
