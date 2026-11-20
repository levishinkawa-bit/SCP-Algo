extends CharacterBody3D

var velDebuf = 0
const vel = Config.base_vel
const sensibilidade = 0.003
var captured = true
var vida := 100
var imune := false
var ded := false

@onready var first_state = {
	pos = self.position,
	rot = self.rotation,
	vel = self.velocity,
	cam_rot = $Camera3D.rotation
	}

func _physics_process(delta: float) -> void:
	velDebuf = 0
	if not is_on_floor():
		velDebuf = 1
		velocity.y -= Config.gravidade * delta
	elif Input.is_action_pressed("pular"):
		velocity.y += Config.jump_power
	else:
		velocity.y = 0
	
	if ded:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	
	var direction = Input.get_vector("esquerda", "direita", "frente", "tras")
	var vector = (transform.basis * Vector3(direction.x, 0, direction.y)).normalized()
	velocity.x = vector.x * (vel - velDebuf)
	velocity.z = vector.z * (vel - velDebuf)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		reset()
	if Input.is_action_just_pressed("unlock_mouse"):
		captured = !captured
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED && captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED && !captured:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not ded:
		rotation.y -= event.relative.x * sensibilidade
		$Camera3D.rotation.x -= event.relative.y * sensibilidade
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func atacar(dano: int):
	if imune: return
	vida = max(vida - dano, 0)
	if vida == 0:
		morte()
	else:
		imune = true
		await get_tree().create_timer(2).timeout

func morte():
	ded = true
	imune = true
	
	get_tree().create_tween().tween_property(self, "rotation_degrees:x", 90, 3)
	get_tree().create_tween().tween_property($Camera3D, "rotation:x", 0, 3)
	await get_tree().create_timer(5).timeout
	var reset_event = InputEventAction.new()
	reset_event.action = "restart"
	reset_event.pressed = true
	Input.parse_input_event(reset_event)
	
	await get_tree().create_timer(0.1).timeout
	reset_event = InputEventAction.new()
	reset_event.action = "restart"
	reset_event.pressed = false
	Input.parse_input_event(reset_event)

func reset():
	position = first_state.get("pos")
	rotation = first_state.get("rot")
	$Camera3D.rotation = first_state.get("cam_rot")
	velocity = first_state.get("vel")
	imune = false
	vida = 100
	ded = false
