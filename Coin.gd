extends Node2D

export (int) var amount = 10
export (int) var timeout = 20


func _on_Area2D_body_entered(body):
	if body.has_method('hero_body_verify'):
		body.add_coin(amount)
		hide()
		$Area2D/CollisionShape2D.disabled = true
		
		$Cooldown.wait_time = timeout
		$Cooldown.start()


func _on_Cooldown_timeout():
	show()
	$Area2D/CollisionShape2D.disabled = false
