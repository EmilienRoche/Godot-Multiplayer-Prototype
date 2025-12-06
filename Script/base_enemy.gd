extends CharacterBody3D

@export var searchOpponent : SearchOpponent
@export var hitbox : Hitbox


var speed : float = 3
var targetPlayer
var isGoingToAttack : bool = false

@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var nav : NavigationAgent3D = $NavigationAgent3D

var rotationSpeed : float = 10

var targetPosition : Vector3
var targetRotation : Vector3
var lerpSpeed : float = 10
var isFreeze : bool = false


func _ready() -> void:
	call_deferred("start_sync_loop")
	# Just copy the material for avoiding all enemies to have the same color when changing it
	var meshMat = $MeshInstance3D.get_active_material(0)
	var newMat = meshMat.duplicate()
	$MeshInstance3D.set_surface_override_material(0, newMat)
	$Marker3D.position = Vector3(0.51, 0.291, -0.754)


func start_sync_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(0.05).timeout
		if multiplayer.is_server():
			rpc("remote_set_transform", global_position, rotation)


@rpc("unreliable")
func remote_set_transform(authorityPosition, authorityRotation):
	targetPosition = authorityPosition
	targetRotation = authorityRotation


@rpc("reliable", "call_local")
func setAnimation(animationName):
	animation.play(animationName)
	await animation.animation_finished
	animation.play_backwards(animationName)


func _process(delta: float) -> void:
	if isFreeze:
		return
	
	# Search an opponent if it as none, and if their is multiple you target one randomly
	if searchOpponent.searchList.size() > 0:
		if targetPlayer == null || !searchOpponent.searchList.has(targetPlayer):
			targetPlayer = searchOpponent.searchList[randi_range(0, searchOpponent.searchList.size() - 1)]
	else:
		targetPlayer = null
	
	if searchOpponent.isInReach != null && !isGoingToAttack:
		isGoingToAttack = true


func _physics_process(delta: float) -> void:
	if isFreeze:
		return
	
	# Only the server manage the enemy
	if !multiplayer.is_server():
		global_position = global_position.lerp(targetPosition, delta * lerpSpeed)
		rotation.y = lerp_angle(rotation.y, targetRotation.y, delta * lerpSpeed)
		return
	
	
	var attacking = searchOpponent.isInReach != null
	
	# Rotate the enemy to always face it's target
	if targetPlayer:
		var target_pos = targetPlayer.global_position
		var direction = Vector3(target_pos.x - global_position.x, 0, target_pos.z - global_position.z)

		if direction.length() > 0.01:
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation + PI, rotationSpeed * delta)
	
	# Only move if not attacking
		if not attacking:
			nav.target_position = targetPlayer.global_position
		else:
			nav.target_position = global_position
	else:
		nav.target_position = global_position
	
	
	# move the enemy and find it's target position to move toward it
	if not attacking and not nav.is_navigation_finished():
		var next_pos = nav.get_next_path_position()
		var dir = (next_pos - global_position).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0

	
	if not is_on_floor():
		velocity.y -= Global.gravity * delta
	
	if searchOpponent.isInReach != null:
		$Marker3D/Sword.attack()
	
	move_and_slide()


func _on_life_died() -> void:
	if multiplayer.is_server():
		get_node("/root/Main/Networking/EnemyManager").request_remove_enemy_character(self.name)
	else:
		get_node("/root/Main/Networking/EnemyManager").rpc_id(1, "request_remove_enemy_character", self.name) 
	

@rpc
func _on_life_as_taked_damage() -> void:
	var base_mat = $MeshInstance3D.get_active_material(0)
	var mat = base_mat.duplicate()
	
	mat.set("albedo_color", Color(0.5, 0, 0))
	$MeshInstance3D.set_surface_override_material(0, mat)
	isFreeze = true
	await get_tree().create_timer(0.5).timeout
	mat.set("albedo_color", Color(1, 0, 0))
	$MeshInstance3D.set_surface_override_material(0, mat)
	isFreeze = false
