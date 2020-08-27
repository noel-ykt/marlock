extends RigidBody2D
signal hit

export var hp = 100
export var speed = 100
var screen_size
var _move_to_pos = Vector2.ZERO
var _moving = false

func _ready():
	hide()
	screen_size = get_viewport_rect().size

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_RIGHT:
			print("Mouse Right Click at: ", event.position)
			_move_to_pos = event.position
			var move_path_vector = _move_to_pos - position
			moveTo(move_path_vector)

func _process(delta):
	if _moving:
		var move_path_vector = _move_to_pos - position
		if move_path_vector.x > 0:
			$AnimatedSprite.play("castle-male-right")
			$AnimatedSprite.flip_h = false
		elif move_path_vector.x < 0:
			$AnimatedSprite.play("castle-male-right")
			$AnimatedSprite.flip_h = true
		if move_path_vector.length() < 2:
			stopMoving()

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

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
