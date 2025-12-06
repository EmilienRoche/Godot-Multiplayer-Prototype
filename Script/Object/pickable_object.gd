@tool
extends RigidBody3D

@export var objectPaths : Dictionary[String, PackedScene]

# set the object to pick directly in the editor to see it
@export var objectToPick: String = "" : set = set_object_to_pick
var currentModelInstance: Node3D = null

var objectRaycast = self
var canDelete = false

# value is the objectToPick string value
func set_object_to_pick(value):
	if objectToPick == value:
		return
	
	objectToPick = value
	
	# If running in the editor
	if Engine.is_editor_hint():
		spawnObjectModel(value)

# Sync is transform with all peer every 5 second
func start_sync_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(5).timeout
		if multiplayer.is_server():
			rpc("remote_set_transform", global_transform)


func _ready() -> void:
	call_deferred("start_sync_loop")
	
	if !get_node_or_null("MeshInstance3D"):
		spawnObjectModel(objectToPick)
	
	await get_tree().create_timer(1).timeout
	$CollisionShape3D.disabled = true


func _process(delta: float) -> void:
	# Delete the pickable object via a variable that is change in the player script
	if multiplayer.is_server() && canDelete:
		get_node("/root/Main/Networking/PickableObjectManager").request_remove_pickable_object(self.name)
	elif canDelete:
		get_node("/root/Main/Networking/PickableObjectManager").rpc_id(1, "request_remove_pickable_object", self.name) 
	
	
	if objectRaycast != self:
		$Label3D.visible = true
		if Input.is_action_just_pressed("interact") && objectRaycast.itemToHold == null:
			print("ITEM HOLD : " + str(objectRaycast.itemToHold))
			canDelete = true
			# objectToHold is a function in the Player script
			objectRaycast.objectToHold(objectToPick)
	else:
		$Label3D.visible = false

# Spawn the object model (Sword, hammer or dagger),
# and make the collisionShape3D the same size as this object model with the createBoxCollision function
func spawnObjectModel(objectPicked: String):
	if currentModelInstance:
		currentModelInstance.queue_free()
		currentModelInstance = null
	
	var oldCollision = get_node_or_null("MeshCollisionShape")
	if oldCollision:
		oldCollision.queue_free()
	
	
	if objectPaths.has(objectPicked):
		var path = objectPaths[objectPicked]
		var packed_scene = path
		if packed_scene:
			currentModelInstance = packed_scene.instantiate()
			add_child(createBoxCollision(currentModelInstance))
			add_child(currentModelInstance)
			currentModelInstance.transform.origin = Vector3.ZERO
	else:
		push_warning("Unknown object type: %s" % objectPicked)

# return the newly collision shape that fit the size of the model
func createBoxCollision(meshInstance : MeshInstance3D):
	var collision = CollisionShape3D.new()
	var boxShape = BoxShape3D.new()
	collision.shape = boxShape
	
	var aabb = meshInstance.get_aabb()
	boxShape.size = aabb.size
	
	collision.transform = meshInstance.transform
	collision.transform.origin += meshInstance.transform.basis * aabb.get_center()
	collision.name = "MeshCollisionShape"
	collision.debug_color = Color(1, 0, 0)
	
	return collision


@rpc("unreliable")
func remote_set_transform(authorityTransform):
	global_transform.origin = global_transform.origin.lerp(authorityTransform.origin, 0.18)
	global_transform.basis = global_transform.basis.slerp(authorityTransform.basis, 0.15)
