extends RigidBody2D

export var speed = 350

var from_player


func _ready():
	$AnimatedSprite.animation = "cast"
	$CollisionShape2D.set_deferred("disabled", true)


func _process(delta):
	if $AnimatedSprite.animation == "cast" && $AnimatedSprite.frame == 3:
		$AnimatedSprite.animation = "fly"
		$CollisionShape2D.set_deferred("disabled", false)
	if $AnimatedSprite.animation == "destroy" && $AnimatedSprite.frame == 2:
		queue_free()


func destroy():
	linear_velocity = Vector2.ZERO
	$AnimatedSprite.animation = "destroy"
	$CollisionShape2D.set_deferred("disabled", true)


func cast(vector):
	linear_velocity = vector.normalized() * speed
	rotation = vector.angle()


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()


func _on_Fireball_body_entered(body: Node):
	print("fireball hit")
	destroy()
