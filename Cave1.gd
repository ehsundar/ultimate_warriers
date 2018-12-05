extends Node2D

var inside_hero


func _on_Area2D_body_entered(body):
	if body.name == 'Hero':
		hero_is_in_front(body)


func hero_is_in_front(body):
	body.in_front_of_cave = self.position


func _on_Area2D_body_exited(body):
	if body.name == 'Hero':
		hero_is_not_in_front(body)


func hero_is_not_in_front(body):
	body.in_front_of_cave = null
