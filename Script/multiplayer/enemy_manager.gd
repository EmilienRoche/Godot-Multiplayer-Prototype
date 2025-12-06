extends Node3D

var addEnemy : bool = false
var enemyList = []
var enemyCounter : int = 0
@onready var enemyContainerNode = $"../../World/Ennemies"
@onready var baseEnemy = preload("res://Scene/baseEnemy.tscn")


func add_enemy(id):
	var baseEnemy = baseEnemy.instantiate()
	baseEnemy.name = str(id)
	enemyContainerNode.add_child(baseEnemy)
	
	print("ENEMY HAS SPAWNED")

# Request to add an enemy, can be call from a client
@rpc("any_peer")
func request_add_enemy():
	rpc("add_newly_enemy", enemyCounter)
	enemyCounter += 1

# ---

# Request to remove an enemy, can be call from a client
@rpc("any_peer")
func request_remove_enemy_character(id):
	remove_enemy_character(id)
	rpc("remove_enemy_character_on_clients", id)

func remove_enemy_character(id):
	if enemyContainerNode.has_node(str(id)):
		enemyContainerNode.get_node(str(id)).queue_free()
	print("Enemy ", id, " is deleted")

@rpc
func remove_enemy_character_on_clients(id):
	remove_enemy_character(id)

# ---

# Register the new enemy and instantiate it on all client + the server
@rpc("authority", "call_local")
func add_newly_enemy(id):
	register_enemy_id(id)
	add_enemy(id)

# Instantiate the enemy for the client that come in the server that as already instantiated enemies in it
@rpc
func add_perviously_instantiated_enemy(eList):
	for id in eList:
		print("ID OF ENEMY : ", id)
		add_enemy(id)

# Register the id of the enemy instantiate to be easily accesible by it's name (the name = id)
@rpc("any_peer")
func register_enemy_id(id):
	if multiplayer.is_server():
		enemyList.append(id)
		rpc("sync_enemy_id", enemyList)

# Sync the enemies id with newly connected client
@rpc
func sync_enemy_id(idList):
	enemyList = idList.duplicate()
