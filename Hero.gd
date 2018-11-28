extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export var on_bottom_ladder = false
export var on_top_ladder = false;

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	$HeroBody.position += Vector2(100, 100)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Ladder_body_entered(body):
	if body == $HeroBody:
		on_bottom_ladder = true


func _on_Ladder_body_exited(body):
	if body == $HeroBody:
		on_bottom_ladder = false


func _on_LowerBound_body_entered(body):
	if body == $HeroBody:
		print("killed by fall")
		$HeroBody.kill()


func _on_LadderTop_body_entered(body):
	if body == $HeroBody:
		on_top_ladder = true


func _on_LadderTop_body_exited(body):
	if body == $HeroBody:
		on_top_ladder = false
