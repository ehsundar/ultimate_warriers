extends Node


var caves = {} # cave_id: cave_tree
var cave_adjacent = {} # cave_id: hero_id
var cave_entered = {} # cave_id: hero_id

var heros = {} # hero_id: hero_tree
var master_hero = null;

var chests = {} # chest_id: chest_tree


func register_cave(cave):
	assert(not cave in caves.values())
	assert(not cave.cave_id in caves.keys())
	assert(cave.cave_id > 0)
	
	caves[cave.cave_id] = cave
	cave_adjacent[cave.cave_id] = null
	cave_entered[cave.cave_id] = null


func register_hero(hero_id, hero_body):
	print(hero_body.hero_name, ': ', hero_id)
	heros[hero_id] = hero_body
	if hero_body.is_network_master():
		master_hero = hero_body


func register_chest(chest):
	assert(not chest in chests.values())
	assert(not chest.id in chests.keys())
	chests[chest.id] = chest


func enter_cave_area(cave, hero_body):
	assert(cave in caves.values())
	assert(hero_body in heros.values())
	cave_adjacent[cave.cave_id] = _get_id_for_hero(hero_body)


func exit_cave_area(cave, hero_body):
	assert(cave in caves.values())
	assert(hero_body in heros.values())
	cave_adjacent[cave.cave_id] = null


func can_enter_any_cave(hero_body):
	assert(hero_body in heros.values())
	var hero_id = _get_id_for_hero(hero_body)
	for cave_id in cave_adjacent.keys():
		if cave_adjacent[cave_id] == hero_id:
			return true
	return false


sync func enter_the_cave_helper(hero_id, cave_id):
	assert(hero_id in heros.keys())
	assert(cave_id in caves.keys())
	var cave = caves[cave_id]
	
	if cave_entered[cave_id] == null:
		cave_entered[cave_id] = hero_id
		heros[hero_id].enter_cave(cave)
	else:
		print('someone else were in cave')
		var hero_in_cave = cave_entered[cave_id]
		heros[hero_in_cave].exit_cave(cave)


func enter_the_cave(hero_body):
	var hero_id = _get_id_for_hero(hero_body)
	var target_cave = -1;
	for cave_id in cave_adjacent.keys():
		if cave_adjacent[cave_id] == hero_id:
			target_cave = cave_id
	if (target_cave == -1):
		print('there is not target cave to enter: ', hero_id)
		return
	rpc("enter_the_cave_helper", hero_id, target_cave)


sync func exit_the_cave_helper(hero_id, cave_id):
	assert(hero_id in heros.keys())
	assert(cave_id in caves.keys())
	
	cave_entered[cave_id] = null
	heros[hero_id].exit_cave(caves[cave_id])


func exit_the_cave(hero_body):
	var hero_id = _get_id_for_hero(hero_body)
	var target_cave = -1;
	for cave_id in cave_entered.keys():
		if cave_entered[cave_id] == hero_id:
			target_cave = cave_id
	if (target_cave == -1):
		print('there is not target cave to exit: ', hero_id)
		return
	rpc("exit_the_cave_helper", hero_id, target_cave)


func add_health_posion(hero_id):
	heros[hero_id].add_posion()
	print('player ' + str(hero_id) + ' got a posion')
		

func add_coin(hero_id, content_amount):
	# rpc('add_coin_helper', hero_id, content_amount)
	heros[hero_id].add_coin(content_amount)
	print('player ' + str(hero_id) + ' got a posion')


func _get_id_for_hero(hero_body):
	for hero_id in heros.keys():
		if heros[hero_id] == hero_body:
			return hero_id
	assert(false)

