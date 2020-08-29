extends RigidBody2D

signal hit

export var hp = 100
export var speed = 100
var screen_size
var _move_to_pos = Vector2.ZERO
var _moving = false

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()

func _ready():
#	hide()
	screen_size = get_viewport_rect().size
	puppet_pos = position

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_RIGHT:
			print("Mouse Right Click at: ", event.position)
			_move_to_pos = event.position
			var move_path_vector = _move_to_pos - position
			moveTo(move_path_vector)

func _physics_process(delta):
	var motion = Vector2()
	if is_network_master():
		if _moving:
			motion = _move_to_pos - position
			if motion.length() < 2:
				stopMoving()
			rset("puppet_motion", motion)
			rset("puppet_pos", position)
	else:
		position = puppet_pos
		motion = puppet_motion

	if motion.x > 0:
		$AnimatedSprite.play("castle-male-right")
		$AnimatedSprite.flip_h = false
	elif motion.x < 0:
		$AnimatedSprite.play("castle-male-right")
		$AnimatedSprite.flip_h = true
	
	if not is_network_master():
		puppet_pos = position
#
#func start(pos):
#	position = pos
#	show()
#	$CollisionShape2D.disabled = false

func stopMoving():
	self.linear_velocity = Vector2.ZERO
	_moving = false
	$AnimatedSprite.stop()

func moveTo(vector):
	self.linear_velocity = vector.normalized() * speed
	_moving = true

func _on_Player_body_entered(body):
	body.destroy()
	emit_signal("hit")
	$CollisionShape2D.set_deferred("disabled", true)
