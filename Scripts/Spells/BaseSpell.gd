class_name BaseSpell
extends RigidBody2D


enum Sounds {}

var _caster = null
var _audio_player: AudioStreamPlayer2D = null
var _collision_shape: CollisionShape2D = null
var _sprite: AnimatedSprite = null

var _resources = {
	"sounds": {},
	"scenes": {}
}


func _load_resources():
	_resources.sounds = _load_sounds()
	_resources.scenes = _load_scenes()

func _load_sounds():
	return {}

func _load_scenes():
	return {}


func _ready():
	_load_resources()


func cast(caster, from_pos, to_pos):
	_caster = caster

func set_animation(name: String):
	pass

func play_sound(name: String, sound_idx: int = -1):
	if _audio_player:
		var sound: AudioStream = null
		if name in _resources.sounds:
			if _resources.sounds[name] is Array:
				if sound_idx > -1 and sound_idx in _resources.sounds[name]:
					sound = _resources.sounds[name][sound_idx]
				elif _resources.sounds[name].size() > 0:
					sound = _resources.sounds[name][randi() % _resources.sounds[name].size()]
			else:
				sound = _resources.sounds[name]

			if sound:
				_audio_player.stream = sound
				_audio_player.play()
		else:
			push_warning("Sound %s does not exists." % name)

func stop_sound():
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
