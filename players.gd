extends Node2D

func _ready():
	pass


func _on_boundary_lower_body_entered(body):
	print("body enter")
	print(body)
	for player in get_children():
		print(player)
		if body == player and player.has_method("kill"):
			player.kill()
