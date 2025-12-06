extends Area3D

var canPickup : bool = false
var raycastColliding
var sceneInteracting

# If it's in the area and the player look at this object, it can put it inside it's inventory

func _on_area_entered(area: Area3D) -> void:
	print("Parent : " + str(get_parent()))
	
	if area.name == "interactionArea3D" && raycastColliding:
		sceneInteracting = area.get_parent()
		canPickup = true


func _process(delta: float) -> void:
	if canPickup && Input.is_action_just_pressed("interact"):
		sceneInteracting.get_node("Inventory").putObjectInInventory(get_parent().objectToPick)
	
