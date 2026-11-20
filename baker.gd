extends NavigationRegion3D

const salas: Dictionary[String, PackedScene] = {
	l = preload("res://salas/sala_l.tscn"),
	u = preload("res://salas/sala_u.tscn"),
	i = preload("res://salas/sala_I.tscn"),
	t = preload("res://salas/sala_t.tscn"),
	x = preload("res://salas/sala_+.tscn")
}

const saidas_para_salas: Dictionary[int, Array] = {
	# z+, x+, z-, x-
	0b1100: [salas["l"], 0],
	0b0110: [salas["l"], 1],
	0b0011: [salas["l"], 2],
	0b1001: [salas["l"], 3],
	
	0b1110: [salas["t"], 0],
	0b0111: [salas["t"], 1],
	0b1011: [salas["t"], 2],
	0b1101: [salas["t"], 3],
	
	0b1000: [salas["u"], 0],
	0b0100: [salas["u"], 1],
	0b0010: [salas["u"], 2],
	0b0001: [salas["u"], 3],
	
	0b1010: [salas["i"], 0],
	0b0101: [salas["i"], 1],
	
	0b1111: [salas["x"], 0]
}

const mapa_x = 20
const mapa_y = 20
const min_to_scps = 40

var mapa = []

func convert_map():
	for y in range(mapa_y):
		for x in range(mapa_x):
			if mapa[y][x] != 0:
				var sala_rot = saidas_para_salas[mapa[y][x]]
				var sala = sala_rot[0].instantiate()
				var rot = deg_to_rad(sala_rot[1] * 90)
				
				sala.rotation.y = rot
				sala.position = Vector3(x * 10, 0, y * 10)
				add_child(sala)

const DIRS = [
	{"vec": Vector2i(0, 1),  "bit": 0b1000, "oposto": 0b0010}, # z+ (y + 1)
	{"vec": Vector2i(1, 0),  "bit": 0b0100, "oposto": 0b0001}, # x+ (x + 1)
	{"vec": Vector2i(0, -1), "bit": 0b0010, "oposto": 0b1000}, # z- (y - 1)
	{"vec": Vector2i(-1, 0), "bit": 0b0001, "oposto": 0b0100}  # x- (x - 1)
]

@warning_ignore("integer_division")
const passos: int = (mapa_x * mapa_y) / 2

var scps := [
	preload("res://scp_096.tscn"),
	preload("res://scp_173.tscn"),
]

func gen_map():
	var pilha: Array[Vector2i] = []
	@warning_ignore("integer_division")
	var inicio = Vector2i(mapa_x / 2, mapa_y / 2)
	pilha.append(inicio)
	
	var max_salas = int((mapa_x * mapa_y) * 0.75)
	var salas_criadas = 1
	
	while not pilha.is_empty() and salas_criadas < max_salas:
		var idx = randi() % pilha.size()
		var atual = pilha[idx]
		var vizinhos_validos = []
		@warning_ignore("integer_division")
		if salas_criadas > min_to_scps and randf() < salas_criadas / (max_salas - scps.size()):
			print(atual)
			var choice = scps.pick_random()
			scps.erase(choice)
			var scp: Node3D = choice.instantiate()
			scp.position = Vector3(atual.x * 10, 5, atual.y * 10)
			
			get_tree().get_first_node_in_group("mundo").add_child.call_deferred(scp)
		
		for dir in DIRS:
			var prox = atual + dir["vec"]
			if prox.x >= 0 and prox.x < mapa_x and prox.y >= 0 and prox.y < mapa_y:
				if mapa[prox.y][prox.x] == 0:
					vizinhos_validos.append(dir)
		
		if not vizinhos_validos.is_empty():
			var escolhido = vizinhos_validos.pick_random()
			var prox = atual + escolhido["vec"]
			
			mapa[atual.y][atual.x] |= escolhido["bit"]
			mapa[prox.y][prox.x] |= escolhido["oposto"]
			
			pilha.append(prox)
			salas_criadas += 1
		else:
			pilha.pop_at(idx)


func _ready() -> void:
	for i in range(mapa_y):
		mapa.append([])
		for j in range(mapa_x):
			mapa[i].append(0)
	
	gen_map()
	convert_map()
	
	get_tree().get_first_node_in_group("player").position = Vector3((mapa_x / 2.0) * 10, 5, (mapa_y / 2.0) * 10)
	
	bake_navigation_mesh()
