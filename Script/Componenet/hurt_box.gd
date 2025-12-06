extends Area3D

@export var lifeComponnent : LifeComponnent

func takeDamage(amount : int):
	lifeComponnent.damage(amount)
	
