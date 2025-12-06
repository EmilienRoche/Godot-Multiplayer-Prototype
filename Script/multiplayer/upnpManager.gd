class_name upnpManager
extends Node

var upnp

func cleanupUPNP(PORT):
	if upnp:
		upnp.delete_port_mapping(PORT, "UDP")
		upnp.delete_port_mapping(PORT, "TCP")
		print("UPNP port mapping removed")
		upnp = null


func startUPNP(PORT):
	upnp = UPNP.new()
	var discoverResult = upnp.discover()
	
	if discoverResult == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var mapResultUdp = upnp.add_port_mapping(PORT, PORT, "godot_udp", "UDP", 0)
			var mapResultTcp = upnp.add_port_mapping(PORT, PORT, "godot_tcp", "TCP", 0)
			
			if not mapResultUdp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(PORT, PORT, "", "UDP")
			if not mapResultTcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(PORT, PORT, "", "TCP")
		
			return upnp.query_external_address() # For connecting to the hosting player
			print("UPNP success ! ")
		else:
			print("No valid UPNP gateway found...")
	else:
		print("UPNP discovery failed: ", discoverResult)
