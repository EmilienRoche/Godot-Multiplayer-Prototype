extends Camera3D

# Configuration du head bob
@export var bob_speed: float = 8.0       # Vitesse de l’oscillation
@export var bob_amount: float = 0.05     # Amplitude de l’oscillation
@export var bob_enabled: bool = true

var bob_timer: float = 0.0
var original_position: Vector3

# Une référence vers le joueur pour vérifier sa vitesse
@onready var player = get_parent().get_parent()

func _ready():
	original_position = position

func _process(delta):
	if not bob_enabled:
		return

	# On suppose que le joueur est un CharacterBody3D
	var velocity = player.velocity
	var is_moving = velocity.length() > 0.1 and player.is_on_floor()

	if is_moving:
		bob_timer += delta * bob_speed
		var offset_y = sin(bob_timer) * bob_amount
		position.y = original_position.y + offset_y
		
		var offset_x = sin(bob_timer * 0.5) * bob_amount * 0.5
		position = original_position + Vector3(offset_x, offset_y, 0)
	else:
		# Retour progressif à la position d'origine
		bob_timer = 0.0
		position.y = lerp(position.y, original_position.y, 10.0 * delta)
