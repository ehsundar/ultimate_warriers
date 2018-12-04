extends Node2D

export (String) var ladder_name = ""
signal proximity(ladder_id, body, is_bottom, is_enter)


func _ready():
	pass

func _process(delta):
	pass


func _on_Ladder_body_entered(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		emit_signal("proximity", ladder_name, body, true, true)


func _on_Ladder_body_exited(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		emit_signal("proximity", ladder_name, body, true, false)


func _on_LadderTop_body_entered(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		emit_signal("proximity", ladder_name, body, false, true)


func _on_LadderTop_body_exited(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		emit_signal("proximity", ladder_name, body, false, false)
