extends Node2D


func _ready():
	pass


func _process(delta):
	pass


func _on_Ladder_proximity(ladder_id, body, is_bottom, is_enter):
	if is_bottom:
		body.set_on_ladder_bottom(is_enter)
	else:
		body.set_on_ladder_top(is_enter)


func _on_LowerBound_body_entered(body):
	if body.has_method('kill'):
		body.kill()
