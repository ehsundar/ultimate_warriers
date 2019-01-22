extends Node


var caves = {}
var cave_adjacent = {}

var hero_bodies = []
var master_hero = null;


func register_cave(cave_tree):
	assert(not cave_tree in caves)
	caves[cave_tree] = null


func register_hero(hero_body):
	hero_bodies.append(hero_body)
	cave_adjacent[hero_body] = null
	if hero_body.is_network_master():
		master_hero = hero_body


func enter_cave_area(cave, hero_body):
	assert(cave in caves)
	assert(hero_body in hero_bodies)
	cave_adjacent[hero_body] = cave


func exit_cave_area(cave, hero_body):
	assert(cave in caves)
	assert(hero_body in hero_bodies)
	cave_adjacent[hero_body] = null


func can_enter_any_cave(hero_body):
	assert(hero_body in hero_bodies)
	return cave_adjacent[hero_body] != null


sync func enter_the_cave_helper(hero_body):
	assert(hero_body in hero_bodies)
	var cave = cave_adjacent[hero_body]
	assert(cave != null)
	
	if caves[cave] == null:
		caves[cave] = hero_body
		hero_body.enter_cave(cave)
	else:
		caves[cave].exit_cave(cave)
	_debug_print_all_caves()

func enter_the_cave(hero_body):
	rpc("enter_the_cave_helper", hero_body)


sync func exit_the_cave_helper(hero_body):
	assert(hero_body in hero_bodies)
	var cave = _hero_in_which_cave(hero_body)
	assert(cave != null)
	
	hero_body.exit_cave(cave)
	caves[cave] = null
	
	_debug_print_all_caves()

func exit_the_cave(hero_body):
	rpc("exit_the_cave_helper", hero_body)


func _hero_in_which_cave(hero_body):
	assert(hero_body in hero_bodies)
	for cave in caves.keys():
		if caves[cave] == hero_body:
			return cave
	return null
	
	
func _debug_print_all_caves():
	print("--debug cave values:")
	for cave in caves.keys():
		print(cave, ": ", caves[cave])
	print("------")


