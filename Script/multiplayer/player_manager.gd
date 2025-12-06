extends Node3D

@onready var playerContainerNode = $"../../World/Players"
var playerNames = {}
@onready var positionPointNode = $"../../World/positionPoin"
@onready var positionPoint : Dictionary = {
	"hub" : positionPointNode.get_node("hubPosition").global_position
}


signal player_disconnected(peer_id)

# Register the player pseudo and call sync_player_names() to Sync it with other peer
@rpc("any_peer")
func register_player_name(pseudo):
	if multiplayer.is_server():
		var senderId = multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() != 0 else 1
		
		playerNames[senderId] = pseudo
		
		rpc("sync_player_names", playerNames)


@rpc
func sync_player_names(names):
	playerNames = names.duplicate()


func add_player(peer_id, connectedPeerIds):
	if playerContainerNode.has_node(str(peer_id)):
		return
	
	if !connectedPeerIds.has(peer_id):
		connectedPeerIds.append(peer_id)
	
	var playerCharacter = preload("res://Scene/proto_controller.tscn").instantiate()
	var playerPseudo = "NONAME"

	if !playerNames.has(peer_id):
		playerNames[peer_id] = playerPseudo
	else:
		playerPseudo = playerNames[peer_id]
	
	print("Adding player ", peer_id, " with pseudo: ", playerPseudo)
	
	playerCharacter.name = str(peer_id)
	playerCharacter.pseudo = playerPseudo
	playerCharacter.global_position = positionPoint["hub"]
	playerCharacter.set_multiplayer_authority(peer_id)
	playerContainerNode.add_child(playerCharacter)

# Add the new client on other peer
@rpc("authority", "call_remote")
func add_newly_connected_player_character(new_peer_id, connectedPeerIds):
	add_player(new_peer_id, connectedPeerIds)

# When new Client connect to ther server, instantiate the player already in game
@rpc
func add_previously_connected_player_characters(peer_ids):
	for peer_id in peer_ids:
		if peer_id != multiplayer.get_unique_id():
			add_player(peer_id, peer_ids)


# ---

# Remove the player when it disconnect
func remove_player(peer_id, connectedPeerIds):
	connectedPeerIds.erase(peer_id)
	if playerContainerNode.has_node(str(peer_id)):
		playerContainerNode.get_node(str(peer_id)).queue_free()
	print("Player ", peer_id, " disconnected")
	player_disconnected.emit(peer_id)

@rpc
func remove_player_on_clients(peer_id, connectedPeerIds):
	remove_player(peer_id, connectedPeerIds)

#---

# Request for removing the player character, can be call from client
@rpc("any_peer")
func request_remove_player_character(peer_id, isRespawningAvailable):
	remove_player_character(peer_id)
	rpc("remove_player_character_on_clients", peer_id)
	
	if isRespawningAvailable:
		respawnPlayer(peer_id)


func remove_player_character(peer_id):
	if playerContainerNode.has_node(str(peer_id)):
		playerContainerNode.get_node(str(peer_id)).queue_free()
	print("Player ", peer_id, " is deleted")

@rpc
func remove_player_character_on_clients(peer_id):
	remove_player_character(peer_id)

# --

# Respawn the player after it as died
func respawnPlayer(peer_id):
	await get_tree().create_timer(1).timeout
	var connectedPeerIds = $"..".connectedPeerIds
	add_player(int(peer_id), connectedPeerIds)
	rpc("add_newly_connected_player_character", int(peer_id), connectedPeerIds)

# Disconnect the player, if it's the player clear the upnp port from the router
func disconnect_player(PORT, upnp, multiplayerPeer):
	if multiplayer.is_server():
		upnp.cleanupUPNP(PORT)
	
	if multiplayerPeer:
		multiplayer.multiplayer_peer.close()
		
	multiplayer.multiplayer_peer = null
	print("Disconnected")
	get_tree().reload_current_scene()
