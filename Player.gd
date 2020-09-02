extends RigidBody2D

signal hit

enum Spell {
	FIREBALL,
	TELEPORT,
}

export var hp := 100
export var speed := 100

var _move_to_pos := Vector2.ZERO
var _moving := false

var _teleporting := false
var _teleport_to := Vector2.ZERO

var _cast_spell = null
var _ready_to_cast := false

puppet var puppet_pos := Vector2()
puppet var puppet_motion := Vector2()

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
			moveTo(move_path_vector)
			
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
				stopMoving()
				_teleport_to = event.position
				_teleporting = true
				_ready_to_cast = false
				_cast_spell = null


func _physics_process(delta):
	
	print(standOnLava())
	
	var motion = Vector2()
	if is_network_master():
		if _moving:
			motion = _move_to_pos - position
			if motion.length() < 2:
				stopMoving()
			
		var castFireball := Input.is_action_pressed("cast_fireball")
		if castFireball:
			_ready_to_cast = true
			_cast_spell = Spell.FIREBALL
		
		var castTeleport := Input.is_action_pressed("cast_teleport")
		if castTeleport:
			_ready_to_cast = true
			_cast_spell = Spell.TELEPORT
		
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


func standOnLava() -> bool:
	var tile_name = getStandsOnTileName()
	return tile_name == 'lava'


func getStandsOnTileName() -> String:
	var player_pos = self.position
	var land: TileMap = get_node("../..").get_node("land_lava")
	var loc = land.world_to_map(player_pos)
	var cell = land.get_cell(loc.x, loc.y)
	if cell != -1:
		return land.tile_set.tile_get_name(cell)
	else:
		return "land"
	

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


func _on_Player_body_entered(body: Node) -> void:
	body.destroy()
	emit_signal("hit")
	$CollisionShape2D.set_deferred("disabled", true)
