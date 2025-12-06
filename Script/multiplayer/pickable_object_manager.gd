extends Node3D

var addPickableObject : bool = false
var pickableObjectList = []
var pickableObjectCounter : int = 0
@onready var pickableObjectContainerNode = $"../../World/PickableObject"

@export var objectPaths : Dictionary[String, PackedScene]
@export var pickableObject : PackedScene

# Request to add a pickable object with the name of the object, can be call from the Client
@rpc("any_peer")
func request_add_pickable_object(thingToSpawn):
	rpc("add_newly_pickable_object", pickableObjectCounter, thingToSpawn)
	pickableObjectCounter += 1


func add_pickable_object(id, thingToSpawn):
	var basePickableObject = pickableObject.instantiate()
	basePickableObject.name = str(id)
	basePickableObject.objectToPick = thingToSpawn
	pickableObjectContainerNode.add_child(basePickableObject)
	
	print("PICKABLE OBJECT HAS SPAWNED")

# ---

# Request to remove the pickable object, can be call from the Client
@rpc("any_peer")
func request_remove_pickable_object(id):
	remove_pickable_object(id)
	rpc("remove_pickable_object_on_clients", id)

# Remove the pickable object via it's id <- (name)
func remove_pickable_object(id):
	if pickableObjectContainerNode.has_node(str(id)):
		pickableObjectContainerNode.get_node(str(id)).queue_free()
	print("Pickable Object ", id, " is deleted")

@rpc
func remove_pickable_object_on_clients(id):
	remove_pickable_object(id)

# ---

@rpc("authority", "call_local")
func add_newly_pickable_object(id, thingToSpawn):
	register_pickable_object_id(id, thingToSpawn)
	add_pickable_object(id, thingToSpawn)

# Add the pickable object in the scene of the new Client 
@rpc
func add_perviously_instantiated_pickable_object(eList):
	for listObject in eList:
		add_pickable_object(listObject[0], listObject[1])

# Register the pickable object to be easily accesible
@rpc("any_peer")
func register_pickable_object_id(id, thingToSpawn):
	if multiplayer.is_server():
		var newPickableObject = [id, thingToSpawn]
		pickableObjectList.append(newPickableObject)
		rpc("sync_pickable_object_id", pickableObjectList)

@rpc
func sync_pickable_object_id(idList):
	pickableObjectList = idList.duplicate()
