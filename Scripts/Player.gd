class_name Player
extends RigidBody2D

enum SpellSlot {
	RIGHT,
	LEFT,
}

enum State {
	
}

export var max_hp := 100
export var current_hp: float= 100
export var speed: float = 100
export var score: int = 0
export var nickname = 'Name The Epithet'
export var player_state = "Alive"

var _is_moving = false
var _move_vector = Vector2.ZERO
var _move_to_pos = Vector2.ZERO

puppet var puppet_hp := 0
puppet var puppet_pos := Vector2()
puppet var puppet_motion := Vector2()


onready var arena = get_node("../..")
onready var _effects = {}
onready var _spells = {
	SpellSlot.LEFT: {
		"scene": ResourceManager.Scene.SPELLS_TELEPORT,
		"func": "cast_teleport",
		"icon": $SpellsIcons/TeleportIcon,
		"is_teleporting": false,
		"telepots_to": Vector2.ZERO,
		"cooldown": 3.0,
		"current_cooldown": 0.0
	},
	SpellSlot.RIGHT: {
		"scene": ResourceManager.Scene.SPELLS_FIREBALL,
		"func": "cast_fireball",
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
	$DebugPanel.add_label("Identifier", "%d (Net: %d)" % [get_instance_id(), get_tree().get_network_unique_id()])
	$DebugPanel.add_label("Position")
	
	if not is_network_master():
		$SpellsIcons.hide()


func _integrate_forces(state):
	if _spells[SpellSlot.LEFT].is_teleporting:
		state.transform = Transform2D(0.0, _spells[SpellSlot.LEFT].telepots_to)
		_spells[SpellSlot.LEFT].is_teleporting = false
		_spells[SpellSlot.LEFT].telepots_to = Vector2.ZERO


func _input(event):
	# Process only own input events
	if is_network_master():
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == BUTTON_RIGHT:
				print("Mouse Right Click at: ", event.position)
				_move_to(event.position)
				get_tree().set_input_as_handled()

		if event is InputEventKey:
			if Input.is_action_pressed("cast_right_spell"):
				if _spells[SpellSlot.RIGHT].current_cooldown <= 0.0:
					cast_spell(SpellSlot.RIGHT)
					get_tree().set_input_as_handled()
				
			if Input.is_action_pressed("cast_left_spell"):
				if _spells[SpellSlot.LEFT].current_cooldown <= 0.0 and _spells[SpellSlot.LEFT].is_teleporting == false:
					cast_spell(SpellSlot.LEFT)
					get_tree().set_input_as_handled()


func _process(delta):
	$DebugPanel.set_label_text("Position", "x: %.2f, y: %.2f" % [position.x, position.y])
	
	for effect in _effects:
		match effect:
			"lava":
				var current_time = OS.get_ticks_msec()
				if _effects[effect].last_tick_time + _effects[effect].delay < current_time:
					_effects[effect].last_tick_time = current_time
					damage(_effects[effect].damage, "lava")

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

	_updateHPBar()
	
	if not is_network_master():
		puppet_pos = position # To avoid jitter


func add_effect(effect):
	if not effect in _effects:
		if effect == "lava":
			_effects["lava"] = {
				last_tick_time = 0,
				delay = 100,
				damage = 1
			}


func remove_effect(effect):
	if effect in _effects:
		_effects.erase(effect)


func cast_spell(spell_name: int):
	var func_name = _spells[spell_name].func
	var cast_target = get_viewport().get_mouse_position()
	_spells[spell_name].current_cooldown = _spells[spell_name].cooldown
	rpc("sync_cast_spell", func_name, get_tree().get_network_unique_id(), cast_target.x, cast_target.y, str(randi()))


remotesync func sync_cast_spell(spell_func: String, caster_id: int, to_x: float, to_y: float, net_name: String):
	var caster: Player = get_node("../%d" % caster_id)
	var from_pos = caster.position
	var to_pos = Vector2(to_x, to_y)
	callv(spell_func, [caster, from_pos, to_pos, net_name])

func cast_fireball(caster: Player, from_pos: Vector2, to_pos: Vector2, net_name: String):
	var fireball = ResourceManager.load_scene(ResourceManager.Scene.SPELLS_FIREBALL)
	arena.add_child(fireball)
	fireball.cast(caster, from_pos, to_pos, net_name)


func cast_teleport(caster: Player, from_pos: Vector2, to_pos: Vector2, net_name: String):
	var teleport = ResourceManager.load_scene(ResourceManager.Scene.SPELLS_TELEPORT)
	arena.add_child(teleport)
	teleport.cast(caster, from_pos, to_pos, net_name)

	caster._stopMoving()
	caster._spells[SpellSlot.LEFT].is_teleporting = true
	caster._spells[SpellSlot.LEFT].telepots_to = to_pos



func damage(value, source) -> void:
	if current_hp > 0.0:
		print("Hit %.3f damage by %s" % [value, source])
		current_hp -= value
	if current_hp <= 0.0:
		current_hp = 0.0
		print("You was killed by %s" % source)
		# rpc_id(source, "addScore", 1)

remotesync func addScore(value) -> void:
	score += value
	$ScoreLabel.text = score as String

func _stopMoving() -> void:
	linear_velocity = Vector2.ZERO
	_is_moving = false
	_updateMovementAnimation(linear_velocity)


func _move_to(to_pos: Vector2) -> void:
	_move_to_pos = to_pos
	_move_vector = _move_to_pos - position
	linear_velocity = _move_vector.normalized() * speed
	_is_moving = true
	_updateMovementAnimation(linear_velocity)


func _updateMovementAnimation(motion: Vector2) -> void:
	# Detect and play or stop the desired animation depending on the motion direction
	if motion == Vector2.ZERO:
		# Freeze current animation on the first frame if player stopped
		$AnimatedSprite.frame = 0
		$AnimatedSprite.stop()
	else:
		# Look away, it's a math
		# Getting a sector (from 0 to 7) of a motion vector to determine animation's index from the array
		# 0 - "left-up", 1 - "left", 2 - "left-down", 3 - "down"
		# 4 - "right-down", 5 - "right", 6 - "right-up" and 7 - "up"
		var sec = int((motion.angle_to(Vector2.DOWN.rotated(-PI/8)) + PI) / (2 * PI) * 8)
		var animations = ["left-up", "left", "left-down", "down", "right-down", "right", "right-up", "up"]
		$AnimatedSprite.animation = animations[sec]
		$AnimatedSprite.play()


func _updateHPBar():
	$HPBar.value = int((float(current_hp) / max_hp) * 100)
