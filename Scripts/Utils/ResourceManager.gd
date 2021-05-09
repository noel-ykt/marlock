extends Node


const _root_path = "res://"
var _cached_resources = {}

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

# TODO: Add cache timeout and garbage collector
func _load(type: int, resource: int, ignore_cache: bool = false):
	var path = _get_resource_path(type, resource)
	if path:
		var lower_type = Type.keys()[type].to_lower()
		var debug_message = "Load %s: %s" % [lower_type, path] # DEBUG
		if ignore_cache or not path in _cached_resources:
			_cached_resources[path] = load(path)
		else: # DEBUG
			debug_message += " from cache" # DEBUG

		print(debug_message) # DEBUG
		return _cached_resources[path]

	return null


# SCENES

enum Scene {
	ARENA, LOBBY, PLAYER, SPELLS_FIREBALL, SPELLS_TELEPORT
}

var _scene_root_path = _root_path + "Scenes/"
var _scene_pathes = {
	Scene.ARENA: "Arena.tscn",
	Scene.LOBBY: "Lobby.tscn",
	Scene.PLAYER: "Player.tscn",

	Scene.SPELLS_FIREBALL: "Spells/FireballSpell.tscn",
	Scene.SPELLS_TELEPORT: "Spells/TeleportSpell.tscn",
}


func load_scene(scene: int, instance: bool = true, ignore_cache: bool = false):
	var loaded_scene = _load(Type.SCENE, scene, ignore_cache)
	if loaded_scene:
		return loaded_scene.instance() if instance else loaded_scene
	
	return null


# SOUNDS

enum Sound {
	FIREBALL_THROW_1,
	FIREBALL_THROW_2,
	FIREBALL_THROW_3,
	FIREBALL_HIT_1,
	FIREBALL_HIT_2,
	TELEPORT_CAST
}

var _sound_root_path = _root_path + "Assets/SFX/"
var _sound_pathes = {
	Sound.FIREBALL_THROW_1: "Fireball Throw 1.wav",
	Sound.FIREBALL_THROW_2: "Fireball Throw 2.wav",
	Sound.FIREBALL_THROW_3: "Fireball Throw 3.wav",
	Sound.FIREBALL_HIT_1: "Fireball Hit 1.wav",
	Sound.FIREBALL_HIT_2: "Fireball Hit 2.wav",
	
	Sound.TELEPORT_CAST: "Teleporting.wav"
}

func load_sound(sound: int, ignore_cache: bool = false):
	return _load(Type.SOUND, sound, ignore_cache)

# SCRIPTS

enum Script {
}

var _script_root_path = _root_path + "Scripts/"
var _script_pathes = {
}

func load_script(script: int, ignore_cache: bool = false):
	return _load(Type.SCRIPT, script, ignore_cache)
