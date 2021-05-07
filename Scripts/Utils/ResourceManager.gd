extends Node


const _root_path = "res://"

enum Type {
	SCENE, SOUND, SCRIPT
}

func _get_resource_path(type: int, resource: int):
	var lower_type = Type.keys()[type].to_lower()
	var capitalized_type = lower_type.capitalize()

	var resource_root_path = get("_%s_root_path" % lower_type)
	var resource_pathes = get("_%s_pathes" % lower_type)
	var resource_enum = get(capitalized_type)

	if resource in resource_pathes:
		var resource_path = resource_root_path + resource_pathes[resource]
		if File.new().file_exists(resource_path):
			return resource_path
		else:
			push_warning(
				"File %s for %s.%s not found." %
				[resource_path, capitalized_type, resource_enum.keys()[resource]]
			)
	elif resource_enum.values().has(resource):
		push_warning(
			"Path for %s.%s is not defined. You should add path to ResourceManager._%s_pathes." %
			[capitalized_type, resource_enum.keys()[resource], lower_type]
		)
	else:
		push_error(
			"%s with index %d not found. Use values of ResourceManager.%s instead." %
			[capitalized_type, resource, capitalized_type]
		)
	return null


# SCENES

enum Scene {
	ARENA, LOBBY, PLAYER, SPELLS_FIREBALL, SPELLS_TELEPORT, ERROR
}

var _scene_root_path = _root_path + "Scenes/"
var _scene_pathes = {
	Scene.ARENA: "Arena.tscn",
	Scene.LOBBY: "Lobby.tscn",
	Scene.PLAYER: "Player.tscn",

	Scene.SPELLS_FIREBALL: "Spells/FireballSpell.tscn",
	Scene.SPELLS_TELEPORT: "Spells/TeleportSpell.tscn",
}


func load_scene(scene: int, instance: bool = true):
	var path = _get_resource_path(Type.SCENE, scene)
	if path:
		print("Load scene: %s" % path)
		return load(path).instance() if instance else load(path)
	
	return null


# SOUNDS

enum Sound {
	FIREBALL_THROW_1,
	FIREBALL_THROW_2,
	FIREBALL_THROW_3,
	FIREBALL_HIT_1,
	FIREBALL_HIT_2,
}

var _sound_root_path = _root_path + "Assets/SFX/"
var _sound_pathes = {
	Sound.FIREBALL_THROW_1: "Fireball Throw 1.wav",
	Sound.FIREBALL_THROW_2: "Fireball Throw 2.wav",
	Sound.FIREBALL_THROW_3: "Fireball Throw 3.wav",
	Sound.FIREBALL_HIT_1: "Fireball Hit 1.wav",
	Sound.FIREBALL_HIT_2: "Fireball Hit 2.wav",
}

func load_sound(sound: int):
	var path = _get_resource_path(Type.SOUND, sound)
	if path:
		print("Load sound: %s" % path)
		return load(path)
	
	return null
