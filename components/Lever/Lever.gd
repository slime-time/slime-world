extends InteractionTarget

signal flip_on
signal flip_off

@onready var area: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $LeverSprite
@onready var active_sprite: AnimatedSprite2D = $ActiveLeverSprite
@onready var timer: Timer = $InteractionTimer

@export var starts_on: bool = false
@export var can_slimes_interact: bool = false
var _is_on: bool = false
var _players_in_area: Dictionary[PlayerMovement, Object] = {}  # Fake hash set

func _ready() -> void:
	area.body_entered.connect(onBodyEntered)
	area.body_exited.connect(onBodyExited)

	if starts_on:
		sprite.play("flip_off")
		sprite.stop()
		active_sprite.play("flip_off_active")
		active_sprite.stop()
		flipOn.call_deferred()
	else:
		sprite.play("flip_on")
		sprite.stop()
		active_sprite.play("flip_on_active")
		active_sprite.stop()
		flipOff.call_deferred()

func onBodyEntered(body: Node) -> void:
	if body is PlayerMovement and body.canInteract():
		if body is Slime and !can_slimes_interact:
			return

		var player = body as PlayerMovement
		player.setInteractionTarget(self)
		_players_in_area[player] = null

		# Set to the active sprite
		active_sprite.visible = true

func onBodyExited(_body: Node) -> void:
	if _body is PlayerMovement and _body.canInteract():
		var player = _body as PlayerMovement
		player.clearInteractionTarget(self)
		_players_in_area.erase(player)

		# Set to the inactive sprite if no more players are in the area
		if _players_in_area.is_empty():
			active_sprite.visible = false

func interact(interactor: PlayerMovement) -> void:

	if !timer.is_stopped() or (interactor is Slime and interactor.slime_type == Slime.Type.ICE_SLIME):
		# Already in the middle of an interaction, ignore
		return
	AudioManager.call_deferred("play_sfx", "switch_click", 1, 1.0)
	if _is_on:
		sprite.play("flip_off")
		active_sprite.play("flip_off_active")
		timer.timeout.connect(flipOff, ConnectFlags.CONNECT_ONE_SHOT)
	else:
		sprite.play("flip_on")
		active_sprite.play("flip_on_active")
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
