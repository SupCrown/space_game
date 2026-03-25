extends RigidBody2D
class_name ToreWorldBody

var outOfScreen = false
var rigidBodyWorldSize : Vector2

func toreWorlBehaviour(worldSize : Vector2):
	rigidBodyWorldSize = worldSize
	outOfScreen = true
		
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if (outOfScreen) :
		verifyAndCorrectPosition(state)
		outOfScreen = false

func verifyAndCorrectPosition(state: PhysicsDirectBodyState2D) :
	if state.transform.origin.x < -(rigidBodyWorldSize[0] / 2):
		state.transform.origin.x = rigidBodyWorldSize[0] / 2
	if state.transform.origin.x > rigidBodyWorldSize[0] / 2:
		state.transform.origin.x = -(rigidBodyWorldSize[0] / 2)
	if state.transform.origin.y < -(rigidBodyWorldSize[1] / 2):
		state.transform.origin.y = rigidBodyWorldSize[1] / 2
	if state.transform.origin.y > rigidBodyWorldSize[1] / 2:
		state.transform.origin.y = -(rigidBodyWorldSize[1] / 2)
