extends RigidBody2D

signal hit

export var hp := 100
export var speed := 100

var _move_to_pos := Vector2.ZERO
var _moving := false

var _ready_to_cast := false
var _ready_to_cast_fireball := false

puppet var puppet_pos := Vector2()
puppet var puppet_motion := Vector2()

func _ready():
	puppet_pos = position


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_RIGHT:
			print("Mouse Right Click at: ", event.position)
			_move_to_pos = event.position
			var move_path_vector = _move_to_pos - position
			moveTo(move_path_vector)
			
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			if (_ready_to_cast):
				print("Mouse Left Click at: ", event.position)
				var move_vector = event.position - position
				_ready_to_cast = false
				_ready_to_cast_fireball = false
				rpc("cast_fireball", position, move_vector, get_tree().get_network_unique_id())

func _physics_process(delta):
	var motion = Vector2()
	if is_network_master():
		if _moving:
			motion = _move_to_pos - position
			if motion.length() < 2:
				stopMoving()
			
		var castFireball = Input.is_action_pressed("cast_fireball")
		if castFireball:
			_ready_to_cast = true
			_ready_to_cast_fireball = true
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
		puppet_pos = position # To avoid jitter


func stopMoving() -> void:
	self.linear_velocity = Vector2.ZERO
	_moving = false
	$AnimatedSprite.stop()


func moveTo(vector: Vector2) -> void:
	self.linear_velocity = vector.normalized() * speed
	_moving = true


remotesync func cast_fireball(pos, vector, by_who):
	var fireball = preload("res://Fireball.tscn").instance()
	fireball.position = pos
	fireball.from_player = by_who
	fireball.cast(vector)
	get_node("../..").add_child(fireball)


func _on_Player_body_entered(body) -> void:
	body.destroy()
	emit_signal("hit")
	$CollisionShape2D.set_deferred("disabled", true)
