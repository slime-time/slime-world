extends InteractionTarget

signal flip_on
signal flip_off

@onready var area: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $LeverSprite
@onready var timer: Timer = $InteractionTimer

@export var can_slimes_interact: bool = false
var _is_on: bool = false

func _ready() -> void:
	area.body_entered.connect(onBodyEntered)
	area.body_exited.connect(onBodyExited)

func onBodyEntered(_body: Node) -> void:
	if _body is PlayerMovement:
		if _body is Slime and !can_slimes_interact:
			return

		var player = _body as PlayerMovement
		player.setInteractionTarget(self)

func onBodyExited(_body: Node) -> void:
	if _body is PlayerMovement:
		var player = _body as PlayerMovement
		player.clearInteractionTarget(self)

func interact(_interactor: PlayerMovement) -> void:
	if !timer.is_stopped():
		# Already in the middle of an interaction, ignore
		return

	if _is_on:
		sprite.play("flip_off")
		timer.timeout.connect(flipOff, ConnectFlags.CONNECT_ONE_SHOT)
	else:
		sprite.play("flip_on")
		timer.timeout.connect(flipOn, ConnectFlags.CONNECT_ONE_SHOT)
	timer.start()

func flipOn() -> void:
	if !_is_on:
		_is_on = true
		emit_signal("flip_on")

func flipOff() -> void:
	if _is_on:
		_is_on = false
		emit_signal("flip_off")
