class_name TeleportSpell
extends BaseSpell


func _load_sounds():
	return {
		"cast": ResourceManager.load_sound(ResourceManager.Sound.TELEPORT_CAST),
	}


func _ready():
	_audio_player = $AudioStreamPlayer2D
	_collision_shape = $CollisionShape2D
	_sprite = $AnimatedSprite

func _process(_delta):
	if _sprite.animation == "cast" and _sprite.frame == 4 and not _audio_player.is_playing():
		queue_free()


func cast(caster, from_pos, to_pos):
	.cast(caster, from_pos, to_pos)
	_collision_shape.set_deferred("disabled", true)
	play_sound("cast")
	_sprite.animation = "cast"
	_sprite.frame = 0
	_sprite.playing = true
	print(caster.nickname)
	position = from_pos
