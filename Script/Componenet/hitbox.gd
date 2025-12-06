extends Area3D
class_name Hitbox

@export var damage : int
@onready var parent = get_parent()
var debugEnteredColor = Color.PURPLE
var debugExitedColor = Color(0.0, 0.6, 0.7)

signal hitingSomething

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))

# Call takeDamage() the area that as enter the hitbox (in this case the HurtBox)
func _on_area_entered(area: Area3D) -> void:
	if area.name == "HurtBox" && area.get_parent() != parent:
		area.takeDamage(damage)
		$CollisionShape3D.debug_color = debugEnteredColor
		emit_signal("hitingSomething")


func _on_area_exited(area: Area3D) -> void:
	if area.name == "HurtBox" && area.get_parent() != parent:
		$CollisionShape3D.debug_color = debugExitedColor


func changeState(state : bool) -> void:
	monitorable = state
	monitoring = state
