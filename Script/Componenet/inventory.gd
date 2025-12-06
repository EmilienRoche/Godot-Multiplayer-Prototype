extends Node3D

var inventory : Array

# Rudimentary inventory to test the object that can be picked by the player

func putObjectInInventory(object : String):
	if inventory.size() < 3:
		inventory.append(object)
	else:
		print("To much object in the inventory !")
	
	print("In Inventory")
	for thing in inventory:
		print(thing)
