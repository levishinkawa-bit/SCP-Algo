extends SCP

var na_tela := false
var olhado := false
var alcançavel := true
var raycasts := [RayCast3D.new(), RayCast3D.new(), RayCast3D.new(), RayCast3D.new(), RayCast3D.new(), RayCast3D.new(), RayCast3D.new(), RayCast3D.new()]

func _ready() -> void:
	super._ready()
	ataque_dist = sqrt(8)
	vel = 3
	$VisibleOnScreenNotifier3D.screen_entered.connect(_screen_entered)
	$VisibleOnScreenNotifier3D.screen_exited.connect(_screen_exited)
	for raycast: RayCast3D in raycasts:
		raycast.enabled = false
		raycast.exclude_parent = true
		raycast.hit_from_inside = true
		add_child(raycast)
	raycasts[0].position = Vector3(0.75, 2.25, 0.75)
	raycasts[1].position = Vector3(0.75, 2.25, -0.75)
	raycasts[2].position = Vector3(-0.75, 2.25, 0.75)
	raycasts[3].position = Vector3(-0.75, 2.25, -0.75)
	raycasts[4].position = Vector3(0.75, 0, 0.75)
	raycasts[5].position = Vector3(0.75, 0, -0.75)
	raycasts[6].position = Vector3(-0.75, 0, 0.75)
	raycasts[7].position = Vector3(-0.75, 0, -0.75)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if olhado or not alcançavel:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()

func _screen_entered():
	na_tela = true
func _screen_exited():
	na_tela = false

func _process(delta: float) -> void:
	alvo = player.global_position
	olhado_check()
	if olhado: return
	virar_ao_alvo(delta, 999)
	tentar_atacar(999)

func olhado_check():
	if na_tela:
		olhado = false
		set_meta("olhado", false)
		
		for raycast in raycasts:
			raycast.enabled = true
			raycast.target_position = raycast.to_local(player.global_position + Vector3.UP)
			raycast.force_raycast_update()
			var col: Object = raycast.get_collider()
		
			if col == player:
				olhado = true
				set_meta("olhado", true)
				break
	else:
		olhado = false
		set_meta("olhado", false)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		reset()
