extends StaticBody3D

@export var holdingCharacter : CharacterBody3D

@onready var hitbox = $Hitbox
@onready var coolDownTimer = $CoolDownTimer
@onready var animationPlayer = $AnimationPlayer
@onready var impactTimeTimer = $ImpactTimeTimer

@export var coolDown : float = 1
@export var impactTime : float = 0.5
@export var speedDecrease : float = 1.5

# the attack function is call by it's owner (the player)

func _ready() -> void:
	impactTimeTimer.wait_time = impactTime
	coolDownTimer.wait_time = coolDown

func attack():
	if !animationPlayer.is_playing() && $CoolDownTimer.is_stopped():
		holdingCharacter.speed /= speedDecrease
		animationPlayer.play("attackAnimation")
		remotePlayAttack.rpc()
		
		await animationPlayer.animation_finished
		animationPlayer.play("afterSimpleAttackAnimation")
		await animationPlayer.animation_finished
		holdingCharacter.speed *= speedDecrease
		$CoolDownTimer.start()
		await $CoolDownTimer.timeout

@rpc("any_peer", "call_remote", "reliable")
func remotePlayAttack():
	animationPlayer.play("attackAnimation")
	await animationPlayer.animation_finished
	animationPlayer.play("afterSimpleAttackAnimation")
	await animationPlayer.animation_finished
	await get_tree().create_timer(coolDown).timeout
	$CoolDownTimer.start()
	await $CoolDownTimer.timeout

@rpc
func _on_hitbox_hiting_something() -> void:
	if animationPlayer.is_playing():
		animationPlayer.speed_scale = 0.5
		$ImpactTimeTimer.start()
		await $ImpactTimeTimer.timeout
		animationPlayer.speed_scale = 1.0

@rpc
func _on_hitbox_area_exited(area: Area3D) -> void:
	animationPlayer.speed_scale = 1.0
