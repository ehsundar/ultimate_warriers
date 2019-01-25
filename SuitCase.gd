extends Node2D


export (String) var team = 'red'
var hero_id = -1
var hero = null


func _ready():
	assert(team == 'red' || team == 'blue')
	if team == 'red':
		$SpriteBlue.hide()
	if team == 'blue':
		$SpriteRed.hide()


func _physics_process(delta):
	if hero:
		position = hero.position + Vector2(0, 15)
		if not hero.delegated_movement:
			visible = hero.visible
		else:
			visible = false


func _on_Area2D_body_entered(body):
	if body.has_method('hero_body_verify'):
		$Area2D/CollisionShape2D.disabled = true
		hero_id = MapState._get_id_for_hero(body)
		hero = body
		z_index = 3


func release_case():
	# sth
	$Area2D/CollisionShape2D.disabled = false
	hero = null
	hero_id = -1
	z_index = 0
