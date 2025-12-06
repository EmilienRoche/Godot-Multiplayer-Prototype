extends CharacterBody3D

var WALK_SPEED = 5.0
var SPRINT_SPEED = 8.0
var speed = WALK_SPEED
var JUMP_VELOCITY = 4.8
var SENSITIVITY = 0.004

# Bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var isDashing : bool = false
var dashTime : float = 0.2
var dashSpeed : float = 25 # 35
var asDash : bool = false

var doubleJumpMaked : bool = false
var airDrag : float = 3

var isWallRide : bool = false
var wallJumpPushSide : float = 15
var wallRideGravityScale : float = 0.15

var isCrouching : bool = false
var crouchingDrag : float = 1.5
var crouchingJump : float = 8

@onready var head = $Head
@onready var camera = $Head/Camera3D

var isSprinting : bool = false
var readyToSync = false
var pseudo = ""

var targetPosition : Vector3
var targetRotation : Vector3
var lerpSpeed : float = 20

@onready var coolDownTimer : Timer = $CoolDownTimer
@onready var raycast = $Head/Camera3D/RayCast3D
var collidingWith = null

var itemToHold = null
@onready var weaponMarker3D = $WeaponMarker3D

var asTakenSprintValue : bool = false
var asTakenWalkValue : bool = true

func _ready():
	# Wait one frame to make sure all things are initialized
	await get_tree().process_frame
	
	# Initialized the player
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Mesh/Label3D.text = str(pseudo)
	targetPosition = global_position
	targetRotation = global_rotation
	
	# Disable the camera if not the authority of this player,
	# Start the sync loop for sending it's position and rotation to other peer
	if is_multiplayer_authority():
		print("Authority confirmed for:", name)
		call_deferred("start_sync_loop")
		await get_tree().create_timer(0.5).timeout
		readyToSync = true
		$Head/Camera3D.current = true
		get_node("/root/Main/CanvasLayer/PlayerUI").visible = true
	else:
		$Head/Camera3D.current = false
	


func _unhandled_input(event):
	if is_multiplayer_authority() && readyToSync:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			
			# Clamp to make the player not be able to make a 360 when looking up
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta):
	# If it's not the player authority, it's just go toward the position send by the player authority
	if !is_multiplayer_authority():
		global_position = global_position.lerp(targetPosition, delta * lerpSpeed)
		global_rotation.y = lerp_angle(rotation.y, targetRotation.y, delta * lerpSpeed)
		return
	
	# Open the Pause Menu
	if Input.is_action_just_pressed("escape"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_node("/root/Main").pauseMenu(true)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_node("/root/Main").pauseMenu(false)
	
	# Look if the raycast is colliding with something 
	# and show the actual life of the player on it's screen
	raycastColliding(raycast)
	showLife()
	
	# Add the gravity.
	if not is_on_floor() and not isWallRide:
		velocity.y -= Global.gravity * delta
	
	if is_on_floor():
		asDash = false
		doubleJumpMaked = false
	
	# Add the gravity on wall slide
	if is_on_wall_only():
		isWallRide = true
		if velocity.y > 0:
			velocity.y -= Global.gravity * delta
		elif velocity.y > -3:
			velocity.y -= Global.gravity * wallRideGravityScale * delta
		else:
			velocity.y = -3
	else:
		isWallRide = false
	
	# Handle the dash
	if Input.is_action_just_pressed("dash"):
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction && !isDashing:
			if is_on_floor():
				velocity.x = direction.x * dashSpeed
				velocity.z = direction.z * dashSpeed
			elif !asDash:
				velocity.x = direction.x * (dashSpeed - 15)
				velocity.z = direction.z * (dashSpeed - 15)
			
			asDash = true
			isDashing = true
			$DashTime.start(dashTime)
	
	# Handle Sprint
	if Input.is_action_pressed("sprint") and (is_on_floor() or is_on_wall_only()):
		isSprinting = true
	else:
		isSprinting = false

	if self.velocity.is_zero_approx():
		isSprinting = false

	# Apply speed only once per mode change
	if isSprinting && !asTakenSprintValue:
		speed = SPRINT_SPEED
		asTakenSprintValue = true
		asTakenWalkValue = false
	elif !isSprinting && !asTakenWalkValue:
		speed = WALK_SPEED
		asTakenWalkValue = true
		asTakenSprintValue = false


	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor() or is_on_wall_only():
		if direction and not isDashing and not isCrouching:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		elif not isCrouching:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		# When you are in the air
		velocity.x = lerp(velocity.x, direction.x * speed, delta * airDrag)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * airDrag)
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not isCrouching:
		# Simple Jump
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and not doubleJumpMaked and not isCrouching:
		# Double Jump
		velocity.y = JUMP_VELOCITY
		doubleJumpMaked = true
	elif Input.is_action_just_pressed("jump") and is_on_floor() and isCrouching:
		# Crouching Jump
		velocity.y = crouchingJump
	
	# Handle Jump on wall
	if Input.is_action_just_pressed("jump") and is_on_wall_only():
		var wall_normal = get_wall_jump_normal()
		wall_normal.y = 0  # On ignore la hauteur pour le push horizontal
		wall_normal = wall_normal.normalized()
		velocity = wall_normal * wallJumpPushSide  # Push à l'opposé du mur
		velocity.y = wallJumpPushSide / 2.5        # Ajoute un saut vertical
	
	# Head bob
	if not isCrouching:
		t_bob += delta * velocity.length() * float(is_on_floor())
		var target_bob = _headbob(t_bob)
		camera.transform.origin = camera.transform.origin.lerp(target_bob, delta * 10.0)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	if Input.is_action_just_pressed("attack") && itemToHold != null:
		print("ITEM TO HOLD" + str(itemToHold))
		itemToHold[0].attack()
	
	move_and_slide()

# -----------------------------------------------------

func start_sync_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(0.05).timeout #0.01
		if is_multiplayer_authority():
			rpc("remote_set_transform", global_position, rotation)


@rpc("unreliable")
func remote_set_transform(authorityPosition, authorityRotation):
	if is_multiplayer_authority():
		return
	
	targetPosition = authorityPosition
	targetRotation = authorityRotation

# -----------------------------------------------------

# Return the normal of the wall to be able to get push away from it when doing a wall jump
func get_wall_jump_normal() -> Vector3:
	for i in range(get_slide_collision_count()):
		var normal = get_slide_collision(i).get_normal()
		# Filter the wall, to not get any floor or ceiling
		if abs(normal.y) < 0.7:
			return normal
	return Vector3.ZERO


func _headbob(time) -> Vector3:
	if velocity.length() < 0.1 or not is_on_floor():
		return Vector3.ZERO
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _on_dash_time_timeout() -> void:
	isDashing = false


func _on_life_died() -> void:
	if multiplayer.is_server():
		get_node("/root/Main/Networking/PlayerManager").request_remove_player_character(self.name, true)
	else:
		get_node("/root/Main/Networking/PlayerManager").rpc_id(1, "request_remove_player_character", self.name, true) 

# Look if the raycast is colliding with a pickable object 
# and send who is colliding with it, with the objectRaycast variable
func raycastColliding(ray : RayCast3D):
	if ray.is_colliding():
		var collider = ray.get_collider()
		var isVariableExist = null
		
		if collider != null:
			isVariableExist = collider.get("objectRaycast")
		
		if isVariableExist != self && isVariableExist != null:
			collider.objectRaycast = self
			collidingWith = collider
	elif collidingWith != null:
		collidingWith.objectRaycast = collidingWith
		collidingWith = null

# Is called by the pickable object script, put the object in the player hand
func objectToHold(object):
	if object != null && itemToHold == null:
		var isRequesteAproved # is not use for the moment 
		if multiplayer.is_server():
			isRequesteAproved = get_node("/root/Main/Networking/PickedObjectManager").request_add_picked_weapon(object, self.get_path())
		else:
			isRequesteAproved = get_node("/root/Main/Networking/PickedObjectManager").rpc_id(1, "request_add_picked_weapon", object, self.get_path()) 
		
		await get_tree().create_timer(0.5).timeout
		print("REQUEST APPROVED : " +  str(isRequesteAproved))
		
		itemToHold = get_node("Head/Camera3D/WeaponMarker3D").get_children()
		itemToHold[0].holdingCharacter = self
		print("ITEM TO HOLD : " + str(itemToHold))


func showLife():
	get_node("/root/Main/CanvasLayer/PlayerUI/LifeLabel").text = str(get_node("Life").health) + "/100"


func _on_life_as_taked_damage() -> void:
	$CanvasLayer.visible = true
	await get_tree().create_timer(0.2).timeout
	$CanvasLayer.visible = false
