extends RigidBody2D

export var speed = 350

var from_player

var sounds = {
	"throw": [
		preload("res://assets/SFX/Fireball Throw 1.wav"),
		preload("res://assets/SFX/Fireball Throw 2.wav"),
		preload("res://assets/SFX/Fireball Throw 3.wav")
	],
	"hit": [
		preload("res://assets/SFX/Fireball Hit 1.wav"),
		preload("res://assets/SFX/Fireball Hit 2.wav")
	]
}


func _ready():
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
