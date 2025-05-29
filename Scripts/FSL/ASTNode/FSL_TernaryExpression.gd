class_name FSLTernaryExpression extends FslASTNode

var condition: FslASTNode
var true_exp: FslASTNode
var false_exp: FslASTNode


func _init(condition, true_ex, false_exp):
	self.condition = condition
	self.true_ex = true_ex
	self.false_exp = false_exp


func to_glsl() -> String:
	return "(%s ? %s : %s)" % [condition.to_glsl(), true_exp.to_glsl(), false_exp.to_glsl()]