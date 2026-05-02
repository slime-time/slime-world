extends CanvasLayer

func _ready() -> void:
	hide();

	SceneManager.pause_state_changed.connect(onPauseStateChanged)

## Hides / shows the pause menu on signal from Scence Manager
func onPauseStateChanged(is_now_paused : bool) -> void:
	visible = is_now_paused

## It does what you think it does
func onResumePressed() -> void:
	print("resuming...")
	SceneManager.unpauseGame()

## It does what you think it does
func onResetPressed() -> void:
	print("resetting...")
	SceneManager.unpauseGame()
	SceneManager.resetScene()

## Unlocks and goes to next level
func onSkipLevelPressed() -> void:
	print("skipping...")
	SceneManager.unpauseGame()
	GameManager.completeLevel()

## Goes back to main menu
func onBackToMenuPressed() -> void:
	print("going back to main menu...")
	SceneManager.unpauseGame()
	GameManager.loadLevel(0)
