extends CanvasLayer

const TRANSITION_SCENE = preload("res://components/SceneTransition/SceneTransition.tscn")
const TRANSITION_TIME_WAIT: float = 0.2
const TRANSITION_TIME_OPEN: float = 0.6
const TRANSITION_TIME_CLOSE: float = 0.6
const TRANSITION_TIME_CLOSE_DELAY: float = 0.0

var transition: ColorRect
var transition_progress: float = 1.0
var tween: Tween

signal transitionFinished

func _ready():
	# Render on top of everything
	layer = 998244353

	# Connect loading and do it now for the first scene (doesn't matter if it's instantiated in menus)
	get_tree().root.child_entered_tree.connect(_onRootChildAdded)
	call_deferred("_onSceneLoaded", get_tree().current_scene)

	transition = TRANSITION_SCENE.instantiate()
	add_child(transition)

# Runs when a direct child of the root node is added so we can detect when a new scene is loaded
func _onRootChildAdded(node : Node) -> void:
	_onSceneLoaded.call_deferred(node)

# Runs on the next update after a direct child node of the root is added (potentially a new scene loaded)
func _onSceneLoaded(node : Node) -> void:
	# Don't do anything if the node that was added isn't the current scene
	if node != get_tree().get_current_scene():
		return

	# If the scene isn't ready yet, wait for it to be ready
	if node.is_node_ready():
		_onSceneReady()
	else:
		node.ready.connect(_onSceneReady)

# Runs when a newly loaded scene becomes ready
func _onSceneReady() -> void:
	if GameManager.current_state.cur_level == 0: _setTransitionProgress(1.0)
	else:
		_setTransitionProgress(0.0)
		startTransitionFromBlack()

func _setTransitionProgress(progress: float) -> void:
	transition_progress = progress
	transition.material.set_shader_parameter("transition_progress", progress)

func startTransitionFromBlack() -> void:
	setDeadEffect(false)

	if tween: tween.kill()
	tween = create_tween()

	# Resume from where we were
	var time_left = TRANSITION_TIME_OPEN * (1.0 - transition_progress)

	if transition_progress == 0.0:
		tween.tween_interval(TRANSITION_TIME_WAIT)

	tween.tween_method(_setTransitionProgress, transition_progress, 1.0, time_left) \
		 .set_trans(Tween.TRANS_SINE) \
		 .set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(transitionFinished.emit)

func startTransitionToBlack(do_delay: bool = false) -> void:
	if tween: tween.kill()
	tween = create_tween()

	var time_left = TRANSITION_TIME_CLOSE * transition_progress

	if do_delay:
		_setTransitionProgress(1.0)
		time_left = TRANSITION_TIME_CLOSE
		tween.tween_interval(TRANSITION_TIME_CLOSE_DELAY)

	tween.tween_method(_setTransitionProgress, transition_progress, 0.0, time_left) \
		 .set_trans(Tween.TRANS_SINE) \
		 .set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(transitionFinished.emit)

func setDeadEffect(value: bool) -> void:
	ShaderTimeManager.setVisualPause(value)
	transition.material.set_shader_parameter("apply_dead_effect", value)
