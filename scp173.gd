extends CharacterBody3D

const vel = Config.base_vel * 3

@onready var first_state = {
	pos = self.position,
	rot = self.rotation,
	vel = self.velocity
	}

var player: CharacterBody3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	$VisibleOnScreenNotifier3D.screen_entered.connect(_screen_entered)
	$VisibleOnScreenNotifier3D.screen_exited.connect(_screen_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= Config.gravidade * delta
	
	if not get_meta("olhado") > 0:
		var vector = (transform.basis * Vector3(0, 0, -1)).normalized() * vel
		velocity.z = vector.z
		velocity.x = vector.x
	else:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()

func _screen_entered():
	set_meta("olhado", get_meta("olhado") + 1)
func _screen_exited():
	set_meta("olhado", get_meta("olhado") - 1)

func _process(_delta: float) -> void:
	if not player or get_meta("olhado") > 0: return
	var alvo = player.global_position

	look_at(alvo)
	rotation.x = 0
	rotation.z = 0

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		position = first_state.get("pos")
		rotation = first_state.get("rot")
		velocity = first_state.get("vel")
