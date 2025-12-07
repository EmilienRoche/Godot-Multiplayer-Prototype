extends Node3D

@onready var UIManager = $"../CanvasLayer"
@onready var enemyManager = $EnemyManager
@onready var playerManager = $PlayerManager
@onready var pickableObjectManager = $PickableObjectManager
@onready var pickedObjectManager = $PickedObjectManager

var multiplayerPeer = ENetMultiplayerPeer.new()

const PORT = 9999
var address = "127.0.0.1"
var upnp : upnpManager = upnpManager.new()
var isUpnpUp : bool = false

var connectedPeerIds = []

# Create and start the server, and also create the player of the server
func start_server():
	UIManager.connection("Server")
	
	if isUpnpUp:
		# Start with UPNP (Univeral Plug And Play) to join wihtout being in the server local network (can join from anywere)
		print("UPNP Started")
		var externalIP = upnp.startUPNP(PORT)
		UIManager.showExternalIP(externalIP)
	else:
		var ip = IP.get_local_addresses()
		UIManager.showExternalIP(str(ip[5]))
	
	# Create the server
	multiplayerPeer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayerPeer
	UIManager.showUniqueID(str(multiplayer.get_unique_id()))
	print("Server started!")
	
	# Spawn the player with id 1 (1 = server)
	var pseudo = UIManager.getPseudo()
	playerManager.register_player_name(pseudo)
	playerManager.add_player(1, connectedPeerIds)
	
	# Look if a new peer connect to the server
	# Sync all the object that are already in the game with the new peer + spawn the player 
	multiplayerPeer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			playerManager.add_player(new_peer_id, connectedPeerIds)
			
			playerManager.rpc_id(new_peer_id, "sync_player_names", playerManager.playerNames)
			await get_tree().create_timer(0.1).timeout
			playerManager.rpc_id(new_peer_id, "add_previously_connected_player_characters", connectedPeerIds)
			playerManager.rpc("add_newly_connected_player_character", new_peer_id, connectedPeerIds)
			
			pickedObjectManager.rpc_id(new_peer_id, "add_perviously_instantiated_picked_weapon", pickedObjectManager.pickedWeaponList)
			enemyManager.rpc_id(new_peer_id ,"add_perviously_instantiated_enemy", enemyManager.enemyList)
			pickableObjectManager.rpc_id(new_peer_id, "add_perviously_instantiated_pickable_object", pickableObjectManager.pickableObjectList)
	)
	
	# Look if a player disconect from the server
	# Remove the player from the game sync with the other client still on the server
	multiplayerPeer.peer_disconnected.connect(
		func(peer_id):
			playerManager.remove_player(peer_id, connectedPeerIds)
			playerManager.rpc("remove_player_on_clients", peer_id, connectedPeerIds)
	)

# Instantiate the new player in the server when clicking on the join button
func start_client():
	UIManager.connection("Client")
	
	# Connect to the server and without calling directly it create the new player with
	# multiplayerPeer.peer_connected.connect() of the create_server() function
	multiplayerPeer.create_client(address, PORT)
	multiplayer.multiplayer_peer = multiplayerPeer
	UIManager.showUniqueID(str(multiplayer.get_unique_id()))
	print("Connected to server !")
	
	await get_tree().create_timer(1).timeout
	var pseudo = UIManager.getPseudo()
	
	# Sync the player pseudo to be able to reader it on other client
	playerManager.rpc_id(1, "register_player_name", pseudo)
	
	# Look if the client disconnect, it reload the scene
	multiplayer.server_disconnected.connect(
		func():
			print("Disconnected from server")
			get_tree().reload_current_scene()
	)


func _on_host_game_button_pressed() -> void:
	start_server()


func _on_join_game_button_pressed() -> void:
	var regex = RegEx.new()
	regex.compile("\\b(?:(?:25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\.){3}(?:25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\b")
	var ipAdressWriten = UIManager.getIPAdress()
	var isIPAdress = regex.search(ipAdressWriten)
	# isIPAdress = true # <- can be put to true for debugging in local (default ip is the local ip address : 127.0.0.1)
	if isIPAdress:
		address = ipAdressWriten
		start_client()

# Disconnect the player via it's own script
func _on_disconnect_button_pressed() -> void:
	playerManager.disconnect_player(PORT, upnp, multiplayerPeer)

# Delete the UPNP port from the router and quit the game
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Game is closing
		if multiplayer.is_server():
			upnp.cleanupUPNP(PORT)
		get_tree().quit()

# -------------------------------------------------------------------------------
