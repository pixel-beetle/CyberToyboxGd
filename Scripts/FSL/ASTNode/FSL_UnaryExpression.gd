class_name FSLUnaryExpression extends FslASTNode
var operator : FslToken
var operand : FslASTNode

func _init(operator : FslToken, operand : FslASTNode):
	self.operator = operator
	self.operand = operand

func to_glsl() -> String:
	return operator.to_glsl() + operand.to_glsl()