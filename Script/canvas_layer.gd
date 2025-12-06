extends CanvasLayer
class_name UIMangager

@onready var networkNode = $"../Networking"
@onready var ipAdressText = $pauseMenu/VBoxContainer/ipAdress
@onready var uniqueIDText = $UniqueID
@onready var pseudoTextEdit = $Connection/pseudoTextEdit
@onready var ipTextEdit = $Connection/IPTextEdit

# Put on the screen if the player is the Server or a Client
func connection(playerType : String):
	$NetworkSideDisplay.text = playerType
	$Connection.visible = false

# Show to the public IP if you host with UPNP Enable
func showExternalIP(externalIP : String):
	ipAdressText.text = externalIP
	print(externalIP)

# Show the id of the player
func showUniqueID(uniqueID : String):
	uniqueIDText.text = uniqueID

# Get the pseudo of the future created Player
func getPseudo():
	var pseudo = pseudoTextEdit.text
	if pseudo == "":
		pseudo = "NONAME"
	return pseudo

# Retrurn the IP address of the player
func getIPAdress():
	return ipTextEdit.text

# Activiate or Desactivate the  server to be use with UPNP
func _on_upnp_enable_check_button_toggled(toggled_on: bool) -> void:
	networkNode.isUpnpUp = toggled_on
