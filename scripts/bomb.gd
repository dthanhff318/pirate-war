extends RigidBody2D

# Timer for explosion
const EXPLOSION_TIME = 2.0

# Explosion properties
@export var explosion_radius = 150.0  # Explosion radius
@export var explosion_damage = 50.0  # Damage dealt
@export var knockback_force = 500.0  # Knockback force

func _ready():
	# Play the initial bomb animation
	if $AnimatedSprite2D.sprite_frames.has_animation("bomb_on"):
		$AnimatedSprite2D.play("bomb_on")

	# Wait 2 seconds, then explode
	await get_tree().create_timer(EXPLOSION_TIME).timeout
	explode()

func explode():
	# Apply explosion effects BEFORE playing animation
	apply_explosion_effects()

	# Play explosion animation
	if $AnimatedSprite2D.sprite_frames.has_animation("bomb_explotion"):
		$AnimatedSprite2D.play("bomb_explotion")
		# Wait for explosion animation to finish, then disappear
		await $AnimatedSprite2D.animation_finished
		queue_free()  # Remove bomb from scene
	else:
		# If explosion animation doesn't exist, just disappear
		queue_free()

func apply_explosion_effects():
	# Get bomb center position
	var bomb_center = global_position

	# Find all physics bodies within explosion radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	# Create CircleShape2D for explosion area
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = Transform2D(0.0, bomb_center)  # Fixed: proper Transform2D
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 0xFFFFFFFF  # Check all collision layers

	# Query all objects in the area
	var results = space_state.intersect_shape(query)

	# Apply damage and knockback to each object
	for result in results:
		var body = result.collider

		# Skip the bomb itself
		if body == self:
			continue

		# Get center position of affected object
		var target_center = body.global_position

		# Calculate vector from bomb center to target center
		var direction = (target_center - bomb_center).normalized()

		# Calculate distance to scale damage/knockback
		var distance = bomb_center.distance_to(target_center)
		var falloff = 1.0 - (distance / explosion_radius)  # 1.0 at center, 0.0 at edge
		falloff = max(falloff, 0.0)  # Ensure non-negative

		# Apply knockback if RigidBody or CharacterBody
		if body is RigidBody2D:
			var knockback = direction * knockback_force * falloff
			body.apply_central_impulse(knockback)
		elif body is CharacterBody2D:
			# For CharacterBody2D (like player), call apply_knockback method
			var knockback = direction * knockback_force * falloff
			if body.has_method("apply_knockback"):
				body.apply_knockback(knockback)
			else:
				# Fallback: directly add to velocity
				body.velocity += knockback

		# Apply damage if object has take_damage method
		if body.has_method("take_damage"):
			var damage = explosion_damage * falloff
			body.take_damage(damage)
