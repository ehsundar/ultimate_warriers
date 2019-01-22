extends Node2D

var inside_hero


func _init():
	MapState.register_cave(self)


func _on_Area2D_body_entered(body):
	if body.has_method('hero_body_verify'):
		MapState.enter_cave_area(self, body)


func _on_Area2D_body_exited(body):
	if body.has_method('hero_body_verify'):
		MapState.exit_cave_area(self, body)

