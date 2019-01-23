extends Node2D


export var id = -1
export var content_type = "HEALTH" # or COIN or RANDOM
export var content_amount = 20

var opened = false


func _ready():
	MapState.register_chest(self)


func _on_Area2D_body_entered(body):
	if opened:
		return
	if body.has_method("hero_body_verify"):
		var hero_id = MapState._get_id_for_hero(body)
		_consume_chest(hero_id)


func _consume_chest(hero_id):
	opened = true
	$SpriteClosed.hide()
	$SpriteOpened.show()
	
	if content_type.to_lower() == 'health':
		MapState.add_health_posion(hero_id)
	if content_type.to_lower() == 'coin':
		MapState.add_coin(hero_id, content_amount)
	if content_type.to_lower() == 'random':
		var rand_type = randi() % 2
		if rand_type == 0:
			MapState.add_health_posion(hero_id)
		if rand_type == 1:
			var rand_amount = int(rand_range(10, 80)) + 1
			MapState.add_coin(hero_id, rand_amount)



