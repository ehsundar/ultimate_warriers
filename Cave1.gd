extends Node2D

export var cave_id = -1;


func _ready():
	MapState.register_cave(self)


func _on_Area2D_body_entered(body):
	if body.has_method('hero_body_verify'):
		MapState.enter_cave_area(self, body)


func _on_Area2D_body_exited(body):
	if body.has_method('hero_body_verify'):
		MapState.exit_cave_area(self, body)

