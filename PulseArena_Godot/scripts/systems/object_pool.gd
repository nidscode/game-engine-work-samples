extends Node
class_name ObjectPool
##
## ObjectPool — generic scene-instance pool.
##
## Bullets churn — we'd rather not allocate/free a node every shot. This pool
## hands out reusable instances and recycles them on request. Nodes are
## expected to expose a `reset()` method (or accept being re-`launch()`-ed)
## before reuse.
##
## Not used by default in this sample (we instantiate for clarity), but
## included to show the pattern is part of the architecture.
##

@export var scene: PackedScene
@export var initial_size: int = 16

var _free: Array[Node] = []
var _all: Array[Node] = []


func _ready() -> void:
	for i in initial_size:
		_grow()


## Returns an inactive instance, growing the pool if needed.
func acquire() -> Node:
	if _free.is_empty():
		_grow()
	var n: Node = _free.pop_back()
	n.process_mode = Node.PROCESS_MODE_INHERIT
	if n.has_method("set_visible"):
		n.set_visible(true)
	return n


## Hand an instance back to the pool. The caller must have already detached
## it from any active gameplay state.
func release(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node.has_method("set_visible"):
		node.set_visible(false)
	if node.get_parent() != self:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		add_child(node)
	_free.append(node)


func _grow() -> void:
	if scene == null:
		push_error("ObjectPool.scene is unassigned.")
		return
	var n := scene.instantiate()
	add_child(n)
	n.process_mode = Node.PROCESS_MODE_DISABLED
	if n.has_method("set_visible"):
		n.set_visible(false)
	_all.append(n)
	_free.append(n)
