extends RigidBody2D

# Timer for explosion
const EXPLOSION_TIME = 2.0

func _ready():
	# Play the initial bomb animation
	if $AnimatedSprite2D.sprite_frames.has_animation("bomb_on"):
		$AnimatedSprite2D.play("bomb_on")

	# Wait 2 seconds, then explode
	await get_tree().create_timer(EXPLOSION_TIME).timeout
	explode()

func explode():
	# Play explosion animation
	if $AnimatedSprite2D.sprite_frames.has_animation("bomb_explotion"):
		$AnimatedSprite2D.play("bomb_explotion")

		# Wait for explosion animation to finish, then disappear
		await $AnimatedSprite2D.animation_finished
		queue_free()  # Remove bomb from scene
	else:
		# If explosion animation doesn't exist, just disappear
		queue_free()
