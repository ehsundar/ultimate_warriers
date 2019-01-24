extends KinematicBody2D

export (int) var default_run_speed = 200
export (int) var default_jump_speed = 400
export (int) var default_gravity = 1200
export (Vector2) var default_spawn_position = Vector2(100, 100)
export (int) var posion_amount = 30


var run_speed = default_run_speed
var jump_speed = default_jump_speed
var gravity = default_gravity
var spawn_position = default_spawn_position
var hero_name = "No Name"

var BulletSmall = preload("BulletSmall.tscn")
var BulletMedium = preload("BulletMedium.tscn")
var BulletLarge = preload("BulletLarge.tscn")
var bullet_level = 1
var reload_duration = 1000

var velocity = Vector2()
var jumping = false
var current_animation_state = "stand"
var last_shoot = 0
var can_shoot = true

var in_cave = false
var in_front_of_cave = null #Vector2

var health = 100
var hero_killed = true
var coins = 0
var posion_count = 0

var delegated_movement = false;
var direction = data_types.RIGHT

slave var slave_velocity = Vector2();
slave var slave_position = Vector2();


func _ready():
	spawn()
	update()
	update_player_status('this is ' + hero_name)
	update_posion_count()
	update_bullet_status()
	update_health_status()
	update_coin_status()


func _process(delta):
	update()


func _physics_process(delta):
	if hero_killed:
		return
	
	if is_network_master():
		update_animation_state()
		
		var right = Input.is_action_pressed('ui_right')
		var left = Input.is_action_pressed('ui_left')
		var up = Input.is_action_pressed('ui_up')
		var down = Input.is_action_just_pressed('ui_down')
		var up_weapon = Input.is_action_just_pressed("upgrade_weapon")
		var up_health = Input.is_action_just_pressed("upgrade_health")
		var select = Input.is_action_just_pressed("ui_select")
		
		if not delegated_movement:
			velocity.x = 0
			
			if is_on_floor():
				jumping = false
			
			if up:
				if is_on_floor():
					if MapState.can_enter_any_cave(self):
						MapState.enter_the_cave(self)
					else:
						velocity.y = -jump_speed
				
			if down:
				if in_cave:
					MapState.exit_the_cave(self)
				
			if right:
				velocity.x += run_speed
				if direction != data_types.RIGHT:
					rpc("set_direction", data_types.RIGHT)
			if left:
				velocity.x -= run_speed
				if direction != data_types.LEFT:
					rpc("set_direction", data_types.LEFT)
			
			velocity.y += gravity * delta
			velocity = move_and_slide(velocity, Vector2(0, -1))
	
		if up_weapon:
			upgrade_bullet()
			
		if up_health:
			upgrade_health()
		
		if select:
			shoot()
			
		rset("slave_position", position)
		rset("slave_velocity", velocity)
	else:
		position = slave_position
		velocity = slave_velocity
	
	if health <= 0 and not hero_killed:
		kill()


func _draw():
	set_as_toplevel(true)
	if health < 0:
		health = 0
	var draw_bar_x = -15
	var draw_bar_y = -30
	draw_rect(Rect2(draw_bar_x, draw_bar_y, 30, 3), Color(1.0, 0.0, 0.0), false)
	draw_rect(Rect2(draw_bar_x, draw_bar_y, health * 3 / 10, 3), Color(1.0, 0.0, 0.0), true)
	
	
	var time_rem = (OS.get_ticks_msec() - last_shoot) * 30 / reload_duration
	if time_rem > 30:
		time_rem = 30
	draw_bar_y += 5
	draw_rect(Rect2(draw_bar_x, draw_bar_y, 30, 3), Color(0.0, 1.0, 0.0), false)
	draw_rect(Rect2(draw_bar_x, draw_bar_y, time_rem, 3), Color(0.0, 1.0, 0.0), true)


sync func set_direction(dir):
	direction = dir


func set_player_name(player_name):
	pass
	#get_node("label").text = player_name


func update_animation_state():
	if health <= 0:
		set_animation_state("dead")
		return
		
	if delegated_movement:
		set_animation_state("ladder")
		return
	else:
		if is_on_floor():
			if OS.get_ticks_msec() - last_shoot > 500:
				if velocity.length() == 0:
					if direction == data_types.RIGHT:
						set_animation_state("stand")
					if direction == data_types.LEFT:
						set_animation_state("stand_left")
				else:
					if direction == data_types.RIGHT:
						set_animation_state("walk")
					if direction == data_types.LEFT:
						set_animation_state("walk_left")
		else:
			if velocity.y < 0:
				set_animation_state("jump_up")
			else:
				set_animation_state("jump_down")


sync func set_anim(state):
	current_animation_state = state
	get_node("AnimatedSprite").play(current_animation_state)

func set_animation_state(state):
	if current_animation_state != state:
		rpc("set_anim", state)


func get_bullet():
	assert(bullet_level > 0)
	assert(bullet_level < 4)
	
	if bullet_level == 1:
		return BulletSmall
	if bullet_level == 2:
		return BulletMedium
	if bullet_level == 3:
		return BulletLarge


sync func apply_shoot(pos, dir):
	last_shoot = OS.get_ticks_msec()
	set_animation_state("attack")
	var bullet = get_bullet().instance()
	bullet.start(pos, dir)
	get_parent().add_child(bullet)
	reload_duration = bullet.reload_duration


func shoot():
	if not can_shoot:
		return
	if OS.get_ticks_msec() - last_shoot < reload_duration:
		return
	rpc("apply_shoot", position, direction)


sync func apply_damage(damage):
	health -= damage
	if health <= 0:
		kill()
	update()
	update_health_status()

func hit(damage):
	rpc("apply_damage", damage)


sync func apply_kill():
	if hero_killed:
		return
	hero_killed = true
	health = 0
	$RespawnTimer.start()
	set_animation_state("dead")
	update_health_status()

func kill():
	rpc("apply_kill")


sync func apply_spawn():
	$PlayerName.text = hero_name
	hero_killed = false
	global_position = spawn_position
	health = 100
	update_health_status()

func spawn():
	rpc("apply_spawn")


sync func upgrade_bullet_helper(value):
	bullet_level = value

func upgrade_bullet():
	if bullet_level < 3:
		if bullet_level == 1:
			if coins >= 160:
				coins -= 160
			else:
				return
		if bullet_level == 2:
			if coins >= 200:
				coins -= 200
			else:
				return
		bullet_level += 1
		update_bullet_status()
		update_coin_status()
		rpc("upgrade_bullet_helper", bullet_level)


func upgrade_health():
	if posion_count > 0:
		posion_count -= 1
		update_posion_count()
		rpc('add_health', posion_amount)


sync func apply_delegated_movement(value):
	delegated_movement = value

func set_delegated_movement(value):
	rpc("apply_delegated_movement", value)


func hero_body_verify():
	pass


func apply_enter_cave(cave):
	self.position = cave.position
	hide()
	disable_movement()
	disable_shooting()
	$CollisionShape2D.disabled = true
	in_cave = true

func enter_cave(cave):
	# rpc("apply_enter_cave", cave)
	apply_enter_cave(cave)
	

func apply_exit_cave(cave):
	show()
	enable_movement()
	enable_shooting()
	$CollisionShape2D.disabled = false
	in_cave = false

func exit_cave(cave):
	# rpc("apply_exit_cave", cave)
	apply_exit_cave(cave)


func disable_movement():
	run_speed = 0
	jump_speed = 0
	gravity = 0
	velocity = Vector2(0, 0)
	
	
func enable_movement():
	run_speed = default_run_speed
	jump_speed = default_jump_speed
	gravity = default_gravity
	

func disable_shooting():
	can_shoot = false


func enable_shooting():
	can_shoot = true


func add_posion():
	if posion_count < 3:
		posion_count += 1
		update_posion_count()


sync func add_health(amount):
	health += amount
	if health > 100:
		health = 100
	update_health_status()


func add_coin(amount):
	coins += amount
	update_coin_status()


func update_player_status(text):
	if is_network_master():
		game_state.world.get_node("GameUi").set_name(text)


func update_posion_count():
	if is_network_master():
		game_state.world.get_node("GameUi").set_posion_count(posion_count)


func update_bullet_status():
	if is_network_master():
		game_state.world.get_node("GameUi").set_bullet(bullet_level)


func update_health_status():
	if is_network_master():
		game_state.world.get_node("GameUi").set_health(health)


func update_coin_status():
	if is_network_master():
		game_state.world.get_node("GameUi").set_coin(coins)







