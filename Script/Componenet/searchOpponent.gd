class_name SearchOpponent
extends Node3D

@export var searchList : Array = []
@export var objectToSearchGroup : String = ""
var isObjectEreaseFromList : bool = false
var isInReach

# Rudimentary searching component for the enemy system (can be improve) 

func _on_search_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group(objectToSearchGroup):
		searchList.append(body)

func _on_search_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group(objectToSearchGroup) && searchList.has(body):
		searchList.erase(body)
		print("Player " + body.name + " is erase form the list")
		isObjectEreaseFromList = true


func _on_stop_search_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group(objectToSearchGroup) && searchList.has(body):
		#searchList.erase(body)
		print("Player " + body.name + " is erase form the list")
		isObjectEreaseFromList = false
		isInReach = body

func _on_stop_search_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group(objectToSearchGroup):
		#searchList.append(body)
		
		isInReach = null
