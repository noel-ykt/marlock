extends Node

export (PackedScene) var Fireball

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	new_game()
	
func _input(event):
	print(event.as_text())

func new_game():
	$Player.start($StartPosition.position)
	$FireballTimer.start()

func game_over():
	pass
#	$FireballTimer.stop()


func _on_FireballTimer_timeout():
	$FireballPath/FirerballSpawnLocation.offset = randi()
	var fireball = Fireball.instance()
	add_child(fireball)
	# Set the mob's direction perpendicular to the path direction.
	var direction = $FireballPath/FirerballSpawnLocation.rotation + PI / 2
	# Set the mob's position to a random location.
	fireball.position = $FireballPath/FirerballSpawnLocation.position
	# Add some randomness to the direction.
	direction += rand_range(-PI / 4, PI / 4)
	fireball.rotation = direction
	# Set the velocity (speed & direction).
	fireball.linear_velocity = Vector2(1, 0)
	fireball.linear_velocity = fireball.linear_velocity.normalized() * fireball.speed
	fireball.linear_velocity = fireball.linear_velocity.rotated(direction)
