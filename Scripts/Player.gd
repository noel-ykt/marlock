class_name Player
extends RigidBody2D

enum Spell {
	FIREBALL,
	TELEPORT,
}

export var max_hp := 100
export var current_hp := 100
export var speed := 100
export var score := 0
export var nickname = 'Name The Epithet'

var _is_moving = false
var _move_vector = Vector2.ZERO
var _move_to_pos = Vector2.ZERO

puppet var puppet_hp := 0
puppet var puppet_pos := Vector2()
puppet var puppet_motion := Vector2()

onready var hp_bar = get_node("HPBar")
onready var land_tilemap: TileMap = get_node("../..").get_node("land_lava")
onready var arena = get_node("../..")
onready var _spells = {
	Spell.TELEPORT: {
		"scene": ResourceManager.Scene.SPELLS_TELEPORT,
		"func": "sync_cast_teleport",
		"icon": $SpellsIcons/TeleportIcon,
		"is_teleporting": false,
		"telepots_to": Vector2.ZERO,
		"cooldown": 3.0,
		"current_cooldown": 0.0
	},
	Spell.FIREBALL: {
		"scene": ResourceManager.Scene.SPELLS_FIREBALL,
		"func": "sync_cast_fireball",
		"icon": $SpellsIcons/FireballIcon,
		"cooldown": 1.0,
		"current_cooldown": 0.0,
	},
}


func set_nickname(new_nickname):
	nickname = new_nickname
	$NameLabel.text = nickname

func _ready():
	puppet_pos = position
	
	if not is_network_master():
		$SpellsIcons.hide()


func _integrate_forces(state):
	if _spells[Spell.TELEPORT].is_teleporting:
		state.transform = Transform2D(0.0, _spells[Spell.TELEPORT].telepots_to)
		_spells[Spell.TELEPORT].is_teleporting = false
		_spells[Spell.TELEPORT].telepots_to = Vector2.ZERO


func _input(event):
	# Process only own input events
	if is_network_master():
		if event is InputEventMouseMotion:
			arena.get_node("DebugLabel").text = str(event.position)

		if event is InputEventMouseButton and event.pressed:
			if event.button_index == BUTTON_RIGHT:
				print("Mouse Right Click at: ", event.position)
				_move_to(event.position)
				get_tree().set_input_as_handled()

		if event is InputEventKey:
			if Input.is_action_pressed("cast_right_spell"):
				if _spells[Spell.FIREBALL].current_cooldown <= 0.0:
					cast_spell(Spell.FIREBALL)
					get_tree().set_input_as_handled()
				
			if Input.is_action_pressed("cast_left_spell"):
				if _spells[Spell.TELEPORT].current_cooldown <= 0.0 and _spells[Spell.TELEPORT].is_teleporting == false:
					cast_spell(Spell.TELEPORT)
					get_tree().set_input_as_handled()


func _process(delta):
	$PositionLabel.text = str(position) # DEBUG
	for key in _spells.keys():
		var spell = _spells[key]
		if spell.current_cooldown > 0.0:
			spell.icon.get_node("Border").border_color = Color("#b01c1c")
			spell.current_cooldown -= delta
			if spell.current_cooldown < 0.0:
				spell.current_cooldown = 0.0
				spell.icon.get_node("Border").border_color = Color("#1cb03a")
			spell.icon.get_node("CooldownProgress").value = int((float(spell.current_cooldown) / spell.cooldown) * 100)


func _physics_process(_delta):
	if isStandsOnLava() and $LavaHitTimer.is_stopped():
		$LavaHitTimer.start()
	
	if not isStandsOnLava() and not $LavaHitTimer.is_stopped():
		$LavaHitTimer.stop()
	
	var motion = Vector2()
	if is_network_master():
		if _is_moving:
			motion = _move_to_pos - position
			if motion.length() < 2:
				_stopMoving()
				motion = Vector2.ZERO
		
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


func cast_spell(spell_name: int):
	var func_name = _spells[spell_name].func
	var cast_target = get_viewport().get_mouse_position()
	_spells[spell_name].current_cooldown = _spells[spell_name].cooldown
	rpc("sync_cast_spell", func_name, get_tree().get_network_unique_id(), cast_target.x, cast_target.y)


remotesync func sync_cast_spell(spell_func: String, caster_id: int, to_x: float, to_y: float):
	var caster: Player = get_node("../%d" % caster_id)
	var from_pos = caster.position
	var to_pos = Vector2(to_x, to_y)
	callv(spell_func, [caster, from_pos, to_pos])

remotesync func sync_cast_fireball(caster: Player, from_pos: Vector2, to_pos: Vector2):
	var fireball = ResourceManager.load_scene(ResourceManager.Scene.SPELLS_FIREBALL)
	arena.add_child(fireball)
	fireball.cast(caster, from_pos, to_pos)


remotesync func sync_cast_teleport(caster: Player, from_pos: Vector2, to_pos: Vector2):
	var teleport = ResourceManager.load_scene(ResourceManager.Scene.SPELLS_TELEPORT)
	arena.add_child(teleport)
	teleport.cast(caster, from_pos, to_pos)

	caster._stopMoving()
	caster._spells[Spell.TELEPORT].is_teleporting = true
	caster._spells[Spell.TELEPORT].telepots_to = to_pos


func isStandsOnLava() -> bool:
	var tile_name = _getStandsOnTileName()
	return tile_name == 'lava'


func _getStandsOnTileName() -> String:
	var loc = land_tilemap.world_to_map(position)
	var cell = land_tilemap.get_cell(loc.x, loc.y)
	if cell != -1:
		return land_tilemap.tile_set.tile_get_name(cell)
	else:
		return "land"


func damage(value, _source) -> void:
	#print("Hit %.3f damage by %s" % [value, source])
	current_hp -= value
	if current_hp <= 0.0:
		pass
		# print("You was killed by %s" % source)
		# rpc_id(source, "addScore", 1)

remotesync func addScore(value) -> void:
	score += value
	$ScoreLabel.text = score as String

func _stopMoving() -> void:
	linear_velocity = Vector2.ZERO
	_is_moving = false
	$AnimatedSprite.stop()


func _move_to(to_pos: Vector2) -> void:
	_move_to_pos = to_pos
	_move_vector = _move_to_pos - position
	linear_velocity = _move_vector.normalized() * speed
	_is_moving = true


func _updateMovementAnimation(motion: Vector2) -> void:
	# Detect and play or stop the desired animation depending on the motion direction
	if motion == Vector2.ZERO:
		# Freeze current animation on the first frame if player stopped
		$AnimatedSprite.frame = 0
		$AnimatedSprite.stop()
	else:
		$AnimatedSprite.flip_h = false
		# Detect - hor or ver movement dominates (with preference for hor)
		if abs(motion.x) >= abs(motion.y) * 0.5:
			$AnimatedSprite.animation = "castle-male-right"
			if motion.x < 0:
				# Reverse "right" animation to "left" if needed
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
