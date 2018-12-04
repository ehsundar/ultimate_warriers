extends Node2D

export (String) var ladder_name = ""
signal proximity(ladder_id, body, is_bottom, is_enter)

var hero_on_ladder = null;
var hero_on_btm = null;
var hero_on_top = null;


func _ready():
	pass


func _process(delta):
	pass


func _physics_process(delta):
	var jump = Input.is_action_pressed('ui_up')
	var crouch = Input.is_action_pressed('ui_down')
	
	if hero_on_ladder:
		if jump:
			hero_on_ladder.global_position += Vector2(0, -200 * delta)
		if crouch:
			hero_on_ladder.global_position += Vector2(0, 200 * delta)
	else:
		if hero_on_btm:
			if jump:
				hero_on_btm.set_delegated_movement(true)
				hero_on_btm.set_state("ladder")
				hero_on_ladder = hero_on_btm
				var dist = $Ladder/CollisionShape2D.global_position.x - hero_on_btm.global_position.x
				hero_on_btm.global_position += Vector2(dist, -200 * delta)
				
		if hero_on_top:
			if crouch:
				hero_on_top.set_delegated_movement(true)
				hero_on_top.set_state("ladder")
				hero_on_ladder = hero_on_top
				var dist = $Ladder/CollisionShape2D.global_position.x - hero_on_top.global_position.x
				hero_on_top.global_position += Vector2(dist, 200 * delta)


func _on_Ladder_body_entered(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		# emit_signal("proximity", ladder_name, body, true, true)
		#hero_on_ladder = body
		pass


func _on_Ladder_body_exited(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		# emit_signal("proximity", ladder_name, body, true, false)
		#hero_on_ladder = null
		pass


func _on_LadderTop_body_entered(body):
	if body == hero_on_ladder:
		hero_on_ladder.global_position += Vector2(0, -30)
		hero_on_ladder.set_delegated_movement(false)
		hero_on_ladder = null
		hero_on_top = body
		
	else:
		if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
			#emit_signal("proximity", ladder_name, body, false, true)
			hero_on_top = body


func _on_LadderTop_body_exited(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		#emit_signal("proximity", ladder_name, body, false, false)
		hero_on_top = null


func _on_LadderBtm_body_entered(body):
	if body == hero_on_ladder:
		hero_on_ladder.set_delegated_movement(false)
		hero_on_ladder = null
		hero_on_btm = body
	else:
		if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
			hero_on_btm = body


func _on_LadderBtm_body_exited(body):
	if body.has_method("set_on_ladder_bottom") and body.has_method("set_on_ladder_top"):
		hero_on_btm = null
