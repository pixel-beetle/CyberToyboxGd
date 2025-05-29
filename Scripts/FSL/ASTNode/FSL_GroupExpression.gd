class_name FslGroupExpression extends FslASTNode
var child : FslASTNode

func _init(child: FslASTNode):
	self.child = child
	
func to_glsl() -> String:
	return "(" + child.to_glsl() + ")"