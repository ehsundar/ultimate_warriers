extends Node2D



func _on_Area2D_body_entered(body):
	if body.has_method('hero_body_verify'):
		if MapState.is_case_holder(body):
			game_state.team_won(body.team)
