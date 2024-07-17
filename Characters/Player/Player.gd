extends CharacterBody2D

@export var base_speed = float() # How fast the player will move (pixels/sec).
@export var sprint_speed = float()
@export var hold_to_walk = bool()
var stored_base_speed
var stored_sprint_speed

@export var attack_speed = float()
@export var hitboxes = {
	"Right": NodePath(),
	"Left": NodePath(),
	"Up": NodePath(),
	"Down": NodePath()
}

@export var walk_animations = {
	"Right": "",
	"Left": "",
	"Up": "",
	"Down": ""
}

@export var attack_animations = {
	"Right": "",
	"Left": "",
	"Up": "",
	"Down": ""
}

var screen_size # Size of the game window.
var can_move = true
var is_sprinting = false
# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	stored_base_speed = base_speed
	stored_sprint_speed = sprint_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	velocity = Vector2.ZERO # The player's movement vector
	if hold_to_walk:
		base_speed = stored_sprint_speed
		sprint_speed = stored_base_speed
	else:
		base_speed = stored_base_speed
		sprint_speed = stored_sprint_speed
	
	
	if can_move:
		# Get movement input and set velocity
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction:
			velocity = direction
		
		# Translate movement directions to attack and hitbox directions
		var input_map = {
			"right": {
				"velocity": Vector2(1,0), 
				"walk_animation": walk_animations["Right"], 
				"attack_animation": attack_animations["Right"], 
				"hitbox": get_node(hitboxes["Right"])
				},
			"left": {
				"velocity": Vector2(-1,0), 
				"walk_animation": walk_animations["Left"], 
				"attack_animation": attack_animations["Left"], 
				"hitbox": get_node(hitboxes["Left"])
				},
			"up": {
				"velocity": Vector2(0,-1), 
				"walk_animation": walk_animations["Up"], 
				"attack_animation": attack_animations["Up"], 
				"hitbox": get_node(hitboxes["Up"])
				},
			"down": {
				"velocity": Vector2(0,1), 
				"walk_animation": walk_animations["Down"], 
				"attack_animation": attack_animations["Down"], 
				"hitbox": get_node(hitboxes["Down"])
				}
		}
		
		# Walk logic
		if velocity.length() > 0:
			var speed
			for input in input_map.keys():
				if velocity == input_map[input]["velocity"]:
					walk(input_map[input]["walk_animation"])
					break
			if Input.is_action_pressed("sprint"):
				speed = sprint_speed
				if !hold_to_walk:
					is_sprinting = true
				else:
					is_sprinting = false
			else:
				speed = base_speed
				if !hold_to_walk:
					is_sprinting = false
				else:
					is_sprinting = true
			move_and_collide((velocity.normalized() * speed) * delta)
		elif $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.stop()
		position = position.clamp(Vector2.ZERO, screen_size)
		
		# Attack logic
		for input in input_map.keys():
			input_map[input]["hitbox"].disabled = true
			if Input.is_action_just_pressed("attack") && $AnimatedSprite2D.animation == input_map[input]["walk_animation"]:
				input_map[input]["hitbox"].disabled = false
				await attack(input_map[input]["attack_animation"])
				input_map[input]["hitbox"].disabled = true
				break
		

func walk(animation):
	var animation_speed = 1
	if is_sprinting:
		animation_speed = (2 / sprint_speed) + 2
	else:
		animation_speed = (2 / base_speed) + 1
	
	$AnimatedSprite2D.animation = animation
	if !$AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.frame = 3
	$AnimatedSprite2D.play(animation, animation_speed)
	print(animation_speed)

func attack(animation):
	can_move = false
	var previousAnimation = $AnimatedSprite2D.animation
	$AnimatedSprite2D.play(animation, attack_speed)
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.animation = previousAnimation
	can_move = true
