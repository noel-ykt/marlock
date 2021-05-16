class_name FireballSpell
extends BaseSpell

export var speed = 350

func _load_sounds():
	return {
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

func _ready():
	_audio_player = $AudioStreamPlayer2D
	_collision_shape = $CollisionShape2D
	_sprite = $AnimatedSprite

func _process(_delta):
	if _sprite.animation == "cast" and _sprite.frame == 3:
		_sprite.animation = "fly"
		_sprite.frame = 0
		_sprite.playing = true
		_collision_shape.set_deferred("disabled", false)
	if _sprite.animation == "destroy" and _sprite.frame == 4 and not _audio_player.is_playing():
		queue_free()

remotesync func destroy():
	play_sound("hit")
	_sprite.animation = "destroy"
	_collision_shape.set_deferred("disabled", true)
	linear_velocity = Vector2.ZERO

func cast(caster, from_pos, to_pos, r):
	.cast(caster, from_pos, to_pos, r)
	$DebugLabel.text = get_name()
	play_sound("throw")
	add_collision_exception_with(caster)
	_sprite.animation = "cast"
	_sprite.frame = 0
	_sprite.playing = true
	position = from_pos
	var move_vector = to_pos - from_pos
	linear_velocity = move_vector.normalized() * speed
	rotation = move_vector.angle()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

func _on_Fireball_body_entered(body: Node):
	if is_network_master():
		rpc("destroy")
		if body.is_in_group("players"):
			print("Fireball hit %s" % body.nickname)
			body.damage(5, _caster)
