extends RigidBody2D

signal hit

enum Spell {
	FIREBALL,
	TELEPORT,
}

export var max_hp := 100
export var current_hp := 100
export var speed := 100
export var score := 0

var _move_to_pos := Vector2.ZERO
var _moving := false

var _teleporting := false
var _teleport_to := Vector2.ZERO

var _cooldowns = {
	Spell.FIREBALL: 1.0,
	Spell.TELEPORT: 3.0
}
var _current_cooldowns = {
	Spell.FIREBALL: 0.0,
	Spell.TELEPORT: 0.0
}

puppet var puppet_hp := 0
puppet var puppet_pos := Vector2()
puppet var puppet_motion := Vector2()

onready var hp_bar = get_node("HPBar")
onready var land_tilemap: TileMap = get_node("../..").get_node("land_lava")
onready var arena = get_node("../..")

func _ready():
	puppet_pos = position


func _integrate_forces(state):
	if _teleporting:
		state.transform = Transform2D(0.0, _teleport_to)
		_teleport_to = Vector2.ZERO
		_teleporting = false


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		
		if event.button_index == BUTTON_RIGHT:
			print("Mouse Right Click at: ", event.position)
			_move_to_pos = event.position
			var move_path_vector = _move_to_pos - position
			_moveTo(move_path_vector)

	if event:
		var now = OS.get_ticks_msec()
		if Input.is_action_pressed("cast_fireball") and _current_cooldowns[Spell.FIREBALL] == 0.0:
			print("Cast: fireball")
			var move_vector = get_viewport().get_mouse_position() - position
			rpc("cast_fireball", position, move_vector, get_tree().get_network_unique_id())
			_current_cooldowns[Spell.FIREBALL] = _cooldowns[Spell.FIREBALL]
			
		if Input.is_action_pressed("cast_teleport") and not _teleporting and _current_cooldowns[Spell.TELEPORT] == 0.0:
			print("Cast: teleport")
			$Teleporting.play()
			_stopMoving()
			_teleport_to = get_viewport().get_mouse_position()
			_teleporting = true
			_current_cooldowns[Spell.TELEPORT] = _cooldowns[Spell.TELEPORT]


func _process(delta):
	for key in _current_cooldowns.keys():
		if _current_cooldowns[key] > 0.0:
			_current_cooldowns[key] -= delta
			if _current_cooldowns[key] < 0.0:
				_current_cooldowns[key] = 0.0


func _physics_process(delta):
	if isStandsOnLava() and $LavaHitTimer.is_stopped():
		$LavaHitTimer.start()
	
	if not isStandsOnLava() and not $LavaHitTimer.is_stopped():
		$LavaHitTimer.stop()
	
	var motion = Vector2()
	if is_network_master():
		if _moving:
			motion = _move_to_pos - position
			if motion.length() < 2:
				_stopMoving()
		
		rset("puppet_hp", current_hp)
		rset("puppet_motion", motion)
		rset("puppet_pos", position)
	else:
		position = puppet_pos
		motion = puppet_motion
		current_hp = puppet_hp
	
	_updateMovementAnimation(motion)
	_updateHPBar()
	
	if not is_network_master():
		puppet_pos = position # To avoid jitter


remotesync func cast_fireball(pos, vector, by_who):
	var fireball = preload("res://Fireball.tscn").instance()
	fireball.position = pos
	fireball.from_player = by_who
	fireball.cast(vector)
	arena.add_child(fireball)
	print("test %s %s" % [
		get_tree().get_network_unique_id(),
		get_tree().get_instance_id()
	])
	rpc_id(get_tree().get_network_unique_id(), "addScore", 1)


func isStandsOnLava() -> bool:
	var tile_name = _getStandsOnTileName()
	return tile_name == 'lava'


func _getStandsOnTileName() -> String:
	var player_pos = self.position
	var loc = land_tilemap.world_to_map(player_pos)
	var cell = land_tilemap.get_cell(loc.x, loc.y)
	if cell != -1:
		return land_tilemap.tile_set.tile_get_name(cell)
	else:
		return "land"


func damage(value, source) -> void:
	#emit_signal("hit")
	print("Hit %.3f damage by %s" % [value, source])
	current_hp -= value
	if current_hp <= 0.0:
		print("You was killed by %s" % source)
		rpc_id(source, "addScore", 1)

remotesync func addScore(value) -> void:
	score += value
	$ScoreLabel.text = score as String

func _stopMoving() -> void:
	self.linear_velocity = Vector2.ZERO
	_moving = false
	$AnimatedSprite.stop()


func _moveTo(vector: Vector2) -> void:
	self.linear_velocity = vector.normalized() * speed
	_moving = true


func _updateMovementAnimation(motion: Vector2) -> void:
	# Detect and play or stop the desired animation depending on the motion direction
	$AnimatedSprite.flip_h = false
	if motion.x == 0 and motion.y == 0:
		# Freeze current animation on first frame when stopped
		$AnimatedSprite.frame = 0
		$AnimatedSprite.stop()
	else:
		# Detect - hor or ver movement dominates (with preference for hor)
		if abs(motion.x) >= abs(motion.y) * 0.5:
			$AnimatedSprite.animation = "castle-male-right"
			# Reverse right animation to left if needed
			if motion.x < 0:
				$AnimatedSprite.flip_h = true
		else:
			if motion.y > 0:
				$AnimatedSprite.animation = "castle-male-down"
			else:
				$AnimatedSprite.animation = "castle-male-up"
		
		$AnimatedSprite.play()


func _updateHPBar():
	hp_bar.value = int((float(current_hp) / max_hp) * 100)


func _on_LavaHitTimer_timeout():
	damage(1, "lava")
