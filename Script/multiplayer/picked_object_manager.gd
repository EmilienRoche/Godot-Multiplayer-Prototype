extends Node3D

var pickedWeaponList = []
var pickedWeaponCounter : int = 0
@export var objPaths : Dictionary[String, PackedScene]


# Request to add the picked weapon, can be call from the Client
# It return a boolean to know if their is the pickable object of the object in the scene
@rpc("any_peer")
func request_add_picked_weapon(weaponToSpawn, objectPath):
	var isRequestApproved = false
	if objPaths.has(weaponToSpawn):
		rpc("add_newly_picked_weapon", pickedWeaponCounter, weaponToSpawn, objectPath)
		pickedWeaponCounter += 1
		isRequestApproved = true
	else:
		isRequestApproved = false
	
	return isRequestApproved

# Add the picked weapon to object (the player) with the variable 
# objectPath that store the path of the place of this object
func add_picked_weapon(id, weaponToSpawn, objectPath):
	print("WEAPON TO SPAWN : " + weaponToSpawn)
	print("ObjPaths : " + str(objPaths))
	var weaponPath
	if objPaths.has(weaponToSpawn):
		weaponPath = objPaths[weaponToSpawn]
	else:
		print("YOU CAN'T")
		return
	var object = get_node(objectPath)
	if weaponPath:
		var basePickedWeapon = weaponPath.instantiate()
		basePickedWeapon.name = str(id)
		object.get_node("Head/Camera3D/WeaponMarker3D").add_child(basePickedWeapon)
		print("PICKED WEAPON HAS SPAWNED")
	else:
		push_warning("Unknown object type: %s" % weaponToSpawn)

# ---

# Request to delete a picked wapon, can be call from Client
@rpc("any_peer")
func request_remove_picked_weapon(id, objectPath):
	remove_picked_weapon(id, objectPath)
	rpc("remove_picked_weapon_on_clients", id, objectPath)

func remove_picked_weapon(id, objectPath):
	var object = get_node(objectPath)
	if object.has_node(str(id)):
		object.get_node(str(id)).queue_free()
	print("Picked Weapon ", id, " is deleted")

@rpc
func remove_pickable_object_on_clients(id, objectPath):
	remove_picked_weapon(id, objectPath)

# ---

# Add to all peer and the server the new picked weapon
@rpc("authority", "call_local")
func add_newly_picked_weapon(id, weaponToSpawn, objectPath):
	register_picked_weapon_id(id, weaponToSpawn, objectPath)
	add_picked_weapon(id, weaponToSpawn, objectPath)

# Add the picked Weapon to all newly connected client
@rpc
func add_perviously_instantiated_picked_weapon(eList):
	for listObject in eList:
		add_picked_weapon(listObject[0], listObject[1], listObject[2])


@rpc("any_peer")
func register_picked_weapon_id(id, weaponToSpawn, objectPath):
	if multiplayer.is_server():
		var newPickableObject = [id, weaponToSpawn, objectPath]
		pickedWeaponList.append(newPickableObject)
		rpc("sync_picked_weapon_id", pickedWeaponList)

@rpc
func sync_picked_weapon_id(idList):
	pickedWeaponList = idList.duplicate()
