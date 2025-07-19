extends Control



func _ready():
	show()
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("space"):  # usually Space or Enter
		get_tree().reload_current_scene()

func diedLabel(points:int, show:bool = true):
	$CanvasLayer/PlayerDiedLabel.text = "You Died \r\n Score: " + str(points) + "\r\n Press Space to Continue"
	$CanvasLayer/PlayerDiedLabel.visible = show

func updatePoints(points:int):
	$CanvasLayer/ScoreLabel.text = "Score: " + str(points)
