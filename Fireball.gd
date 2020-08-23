extends RigidBody2D

export var speed = 250

func _ready():
	$AnimatedSprite.animation = "fly"

func _physics_process(delta):
	linear_velocity = Vector2(speed, 0)

func _process(delta):
	if $AnimatedSprite.animation == "destroy" && $AnimatedSprite.frame == 2:
		queue_free()

func destroy():
	linear_velocity = Vector2.ZERO
	$AnimatedSprite.animation = "destroy"
	$CollisionShape2D.set_deferred("disabled", true)
	pass

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

func _on_Fireball_body_entered(body):
	destroy()
