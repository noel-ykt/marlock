extends RigidBody2D
signal hit

export (PackedScene) var Fireball

export var hp = 100
export var speed = 100
var screen_size
var _move_to_pos = Vector2.ZERO
var _moving = false

func _ready():
	hide()
	screen_size = get_viewport_rect().size

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_SPACE:
			castFireball()
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_RIGHT:
		print("Mouse Right Click at: ", event.position)
		_move_to_pos = event.position
		var move_path_vector = _move_to_pos - position
		moveTo(move_path_vector)

func _process(delta):
	if _moving:
		var move_path_vector = _move_to_pos - position
		if move_path_vector.length() < 2:
			self.linear_velocity = Vector2.ZERO
			_moving = false

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

func castFireball():
	var fireball = Fireball.instance()
	get_node("/root/Main").add_child(fireball)
	
	fireball.global_position = position
	fireball.global_position.x += 20
	fireball.rotation_degrees = 90

func moveTo(vector):
	self.linear_velocity = vector.normalized() * speed
	_moving = true

func _on_Player_body_entered(body):
	body.destroy()
	emit_signal("hit")
	$CollisionShape2D.set_deferred("disabled", true)
