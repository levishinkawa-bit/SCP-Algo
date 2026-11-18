extends CharacterBody3D

const vel = Config.base_vel * 3

@onready var first_state = {
	pos = self.position,
	rot = self.rotation,
	vel = self.velocity
	}

var player: CharacterBody3D
var olhado := false
var raycast: RayCast3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	$VisibleOnScreenNotifier3D.screen_entered.connect(_screen_entered)
	$VisibleOnScreenNotifier3D.screen_exited.connect(_screen_exited)
	raycast = RayCast3D.new()
	raycast.enabled = false
	raycast.exclude_parent = true
	add_child(raycast)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= Config.gravidade * delta
	
	if not olhado:
		var vector = (transform.basis * Vector3(0, 0, -1)).normalized() * vel
		velocity.z = vector.z
		velocity.x = vector.x
	else:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()

func _screen_entered():
	set_meta("olhado", true)
	olhado = true
func _screen_exited():
	set_meta("olhado", false)
	olhado = false

func _process(_delta: float) -> void:
	if not player or olhado: return
	var alvo = player.global_position

	look_at(alvo)
	rotation.x = 0
	rotation.z = 0
	
	var diff := player.position - position
	diff *= diff
	if not olhado and (diff.x + diff.y + diff.z) < 4:
		raycast.enabled = true
		raycast.target_position = raycast.to_local(player.global_position)
		raycast.force_raycast_update()
		if raycast.is_colliding():
			if raycast.get_collider() == player or raycast.get_collider() in player.get_children():
				player.atacar(999)
		raycast.enabled = false
	

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		position = first_state.get("pos")
		rotation = first_state.get("rot")
		velocity = first_state.get("vel")
