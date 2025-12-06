@tool
extends StaticBody3D

var isPlayerEnter : bool = false
@export var listOfThingToSpawn : Array = ["Ennemy", "PickableObject"]
var pickableObjectName : String = ""

# Be able to know what "thing" it can spawn by showing it via a label
@export var thingToSpawn : String :
	set(value):
		thingToSpawn = value
		$ThingToSpawnLabel.text = value

@export_category("Pickable Object")
@export var isRandomSpawn : bool = false
@export var objectToSpawn : String = ""


func _process(delta: float) -> void:
	if isPlayerEnter && Input.is_action_just_pressed("interact"):
		match thingToSpawn:
			"Ennemy":
				if multiplayer.is_server():
					var enemyManager = get_node("/root/Main/Networking/EnemyManager")
					enemyManager.request_add_enemy()
				else:
					var enemyManager = get_node("/root/Main/Networking/EnemyManager")
					enemyManager.rpc_id(1, "request_add_enemy")

				get_node("/root/Main/Networking/EnemyManager").addEnemy = true
			"PickableObject":
				if isRandomSpawn:
					var rand = randi_range(0, 2)
					objectToSpawn = chooseOne(rand)
				if multiplayer.is_server():
					var pickableObjectManager = get_node("/root/Main/Networking/PickableObjectManager")
					pickableObjectManager.request_add_pickable_object(objectToSpawn)
				else:
					var pickableObjectManager = get_node("/root/Main/Networking/PickableObjectManager")
					pickableObjectManager.rpc_id(1, "request_add_pickable_object", objectToSpawn)
		
		print("click")


func chooseOne(rand : int) -> String:
	var object = "Sword"
	match rand:
		0:
			object = "Sword"
		1:
			object = "Dagger"
		2:
			object = "AnvilHammer"
	
	return object


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		isPlayerEnter = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		isPlayerEnter = false
