class_name BaseSpell
extends RigidBody2D


var sounds = {}
var audio_player: AudioStreamPlayer2D = null


func _ready():
	pass


func cast():
	pass


func play_sound(sound_name: String, sound_idx: int = -1):
	if audio_player:
		var sound: AudioStream = null
		if sound_name in sounds:
			
			audio_player.stream = sounds["throw"][randi() % sounds["throw"].size()]
		audio_player.play()

func stop_sound():
	if audio_player:
		audio_player.stop()
