class_name FireballSpell
extends BaseSpell

export var speed = 350

var from_player


func _ready():
	sounds = {
		"throw": [
			ResourceManager.load_sound(ResourceManager.Sound.FIREBALL_THROW_1),
			ResourceManager.load_sound(ResourceManager.Sound.FIREBALL_THROW_2),
			ResourceManager.load_sound(ResourceManager.Sound.FIREBALL_THROW_3),
		],
		"hit": [
			ResourceManager.load_sound(ResourceManager.Sound.FIREBALL_HIT_1),
			ResourceManager.load_sound(ResourceManager.Sound.FIREBALL_HIT_2),
		]
	}
	audio_player = $AudioStreamPlayer2D
	$AnimatedSprite.animation = "cast"
	$CollisionShape2D.set_deferred("disabled", true)


func _process(_delta):
	if $AnimatedSprite.animation == "cast" && $AnimatedSprite.frame == 3:
		$AnimatedSprite.animation = "fly"
		$CollisionShape2D.set_deferred("disabled", false)
	if $AnimatedSprite.animation == "destroy" && $AnimatedSprite.frame == 3 and not $AudioStreamPlayer2D.is_playing():
		queue_free()


func destroy():
	$AudioStreamPlayer2D.stream = sounds["hit"][randi() % sounds["hit"].size()]
	$AudioStreamPlayer2D.play()
	linear_velocity = Vector2.ZERO
	$AnimatedSprite.animation = "destroy"
	$CollisionShape2D.set_deferred("disabled", true)


func cast(vector):
	$AudioStreamPlayer2D.stream = sounds["throw"][randi() % sounds["throw"].size()]
	$AudioStreamPlayer2D.play()
	linear_velocity = vector.normalized() * speed
	rotation = vector.angle()


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()


func _on_Fireball_body_entered(body: Node):
	print("Fireball hit to %s" % body.get_instance_id())
	destroy()
	if body.is_in_group("players"):
		body.damage(5, from_player)
