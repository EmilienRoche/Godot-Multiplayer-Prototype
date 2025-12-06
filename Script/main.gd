extends Node3D

# Activate or Desactivate the menu
func pauseMenu(activateMenu : bool):
	var menu = $CanvasLayer/pauseMenu
	menu.visible = activateMenu
