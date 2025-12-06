extends Node3D
class_name LifeComponnent

@export var MAX_HEALTH : int
var health : int

signal died
signal asTakedDamage

func _ready() -> void:
	health = MAX_HEALTH

func damage(damage : int):
	health -= damage
	emit_signal("asTakedDamage")
	print(get_parent().name + " have " + str(health))
	
	if health <= 0:
		emit_signal("died")
