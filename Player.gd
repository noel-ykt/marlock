extends RigidBody2D

signal hit

enum Spell {
	FIREBALL,
	TELEPORT,
}

export var max_hp := 100
export var current_hp := 100
export var speed := 100

var _move_to_pos := Vector2.ZERO
var _moving := false

var _teleporting := false
var _teleport_to := Vector2.ZERO

var _cast_spell = null
var _ready_to_cast := false

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
			
		if event.button_index == BUTTON_LEFT and _ready_to_cast:
			print("Mouse Left Click at: ", event.position)

			if _cast_spell == Spell.FIREBALL:
				print("Cast: fireball")
				_ready_to_cast = false
				_cast_spell = null
				var move_vector = event.position - position
				rpc("cast_fireball", position, move_vector, get_tree().get_network_unique_id())
				
			if _cast_spell == Spell.TELEPORT:
				print("Cast: teleport")
				_stopMoving()
				_teleport_to = event.position
				_teleporting = true
				_ready_to_cast = false
				_cast_spell = null


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
			
		var castFireball := Input.is_action_pressed("cast_fireball")
		if castFireball:
			_ready_to_cast = true
			_cast_spell = Spell.FIREBALL
		
		var castTeleport := Input.is_action_pressed("cast_teleport")
		if castTeleport:
			_ready_to_cast = true
			_cast_spell = Spell.TELEPORT
		
		rset("puppet_hp", current_hp)
		rset("puppet_motion", motion)
		rset("puppet_pos", position)
	else:
		position = puppet_pos
		motion = puppet_motion
		current_hp = puppet_hp

	if motion.x > 0:
		$AnimatedSprite.play("castle-male-right")
		$AnimatedSprite.flip_h = false
	elif motion.x < 0:
		$AnimatedSprite.play("castle-male-right")
		$AnimatedSprite.flip_h = true
		
	_updateHPBar()
	
	if not is_network_master():
		puppet_pos = position # To avoid jitter


remotesync func cast_fireball(pos, vector, by_who):
	var fireball = preload("res://Fireball.tscn").instance()
	fireball.position = pos
	fireball.from_player = by_who
	fireball.cast(vector)
	arena.add_child(fireball)


func isStandsOnLava() -> bool:
	var tile_name = _getStandsOnTileName()
	return tile_name == 'lava'


func _onHit(damage) -> void:
	emit_signal("hit")
	current_hp -= damage


func _getStandsOnTileName() -> String:
	var player_pos = self.position
	var loc = land_tilemap.world_to_map(player_pos)
	var cell = land_tilemap.get_cell(loc.x, loc.y)
	if cell != -1:
		return land_tilemap.tile_set.tile_get_name(cell)
	else:
		return "land"


func damage(damage):
	_onHit(damage)


func _stopMoving() -> void:
	self.linear_velocity = Vector2.ZERO
	_moving = false
	$AnimatedSprite.stop()


func _moveTo(vector: Vector2) -> void:
	self.linear_velocity = vector.normalized() * speed
	_moving = true


func _updateHPBar():
	hp_bar.value = int((float(current_hp) / max_hp) * 100)


func _on_LavaHitTimer_timeout():
	print("hit lava")
	damage(1)
