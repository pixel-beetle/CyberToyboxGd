class_name FSLTernaryExpression extends FslASTNode

var condition: FslASTNode
var true_exp: FslASTNode
var false_exp: FslASTNode


func _init(c : FslASTNode, true_exp : FslASTNode, false_exp : FslASTNode):
	self.condition = c
	self.true_exp = true_exp
	self.false_exp = false_exp


func to_glsl() -> String:
	return "(%s ? %s : %s)" % [condition.to_glsl(), true_exp.to_glsl(), false_exp.to_glsl()]
