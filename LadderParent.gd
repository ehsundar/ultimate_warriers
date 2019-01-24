extends Node2D

export (int) var ladder_id = -1
export (int) var height = 3


var hero_on_ladder = null;
var hero_on_btm = null;
var hero_on_top = null;


func _ready():
	$LadderTop.position += Vector2(0, -30 * height) + Vector2(0, -20)
	

func _process(delta):
	pass


func _physics_process(delta):
	var jump = Input.is_action_pressed('ui_up')
	var crouch = Input.is_action_pressed('ui_down')
	
	if hero_on_ladder:
		hero_on_ladder.set_animation_state("ladder")
		if jump:
			hero_on_ladder.global_position += Vector2(0, -200 * delta)
		if crouch:
			hero_on_ladder.global_position += Vector2(0, 200 * delta)
	else:
		if hero_on_btm and jump:
			hero_on_ladder = hero_on_btm
			hero_on_ladder.set_delegated_movement(true)
			var dist = global_position.x - hero_on_ladder.global_position.x
			hero_on_ladder.global_position += Vector2(dist, -200 * delta)
				
		if hero_on_top and crouch:
			hero_on_ladder = hero_on_top
			hero_on_ladder.set_delegated_movement(true)
			var dist = global_position.x - hero_on_ladder.global_position.x
			hero_on_ladder.global_position += Vector2(dist, 200 * delta)


func _on_LadderTop_body_entered(body):
	if body == hero_on_ladder:
		hero_on_ladder.global_position += Vector2(0, -40)
		hero_on_ladder.set_delegated_movement(false)
		hero_on_ladder = null
	
	if body.has_method('hero_body_verify'):
		hero_on_top = body


func _on_LadderTop_body_exited(body):
	if body.has_method('hero_body_verify'):
		hero_on_top = null


func _on_LadderBtm_body_entered(body):
	if body == hero_on_ladder:
		hero_on_ladder.set_delegated_movement(false)
		hero_on_ladder = null
	
	if body.has_method('hero_body_verify'):
		hero_on_btm = body


func _on_LadderBtm_body_exited(body):
	if body.has_method('hero_body_verify'):
		hero_on_btm = null
