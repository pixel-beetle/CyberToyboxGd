class_name FslParser

# 运算符优先级表
const PRECEDENCE: Dictionary = {
								   "||": 1,
								   "&&": 2,
								   "==": 3, "!=": 3,
								   "<": 4, ">": 4, "<=": 4, ">=": 4,
								   "+": 5, "-": 5,
								   "*": 6, "/": 6, "%": 6,
								   "**": 7
							   }

# 解析器主体
var tokens: Array[FslToken]
var current_token: FslToken
var position: int = 0

class ParseContext:
	var success : bool = false
	var message : String = ""
	var ast : FslASTNode = null
	var valid_variables : Array[String] = []
	var valid_functions : Array[String] = []

# 主解析函数
func parse(expression: String, valid_functions : Array[String], valid_variables : Array[String]) -> ParseContext:
	tokens = _tokenize(expression)
	var state := ParseContext.new();
	if tokens.size() == 0:
		state.success = false;
		state.message = "No Valid Token";
		return state;
	position = 0;
	current_token = tokens[0];
	state.valid_variables = valid_variables;
	state.valid_functions = valid_functions;
	state.success = true;
	state.ast = _parse_expression(state);
	return state


# 正则表达式词法分析器
func _tokenize(expression: String) -> Array[FslToken]:
	var tokens      :  Array[FslToken] = []
	var pos: int    = 0
	var length: int = expression.length()

	while pos < length:
		var substr: String = expression.substr(pos)

		# 跳过空白字符
		if substr.begins_with(" ") or substr.begins_with("\t") or substr.begins_with("\n") or substr.begins_with("\r"):
			pos += 1
			continue

		var matched: bool = false

		# 尝试匹配所有token模式
		for pattern in FslToken.TOKEN_PATTERNS:
			var regex = RegEx.new()
			var err   = regex.compile(pattern.regex)
			if err != OK:
				push_error("Regex compilation error: " + pattern.regex)
				continue

			var result = regex.search(substr)
			if result:
				# 提取匹配值
				var value = pattern.get("value", result.get_string())
				# 创建token
				tokens.append(FslToken.new(pattern.type, value, pos))
				pos += result.get_string().length()
				matched = true
				break

		# 未匹配任何token模式
		if not matched:
			push_error("Unexpected character at position %d: '%s'" % [pos, expression[pos]])
			return []

	tokens.append(FslToken.new(FslToken.Type.EOF, "", pos))
	return tokens


# 获取下一个token
func _advance():
	position += 1
	if position < tokens.size():
		current_token = tokens[position]
	else:
		current_token = FslToken.new(FslToken.Type.EOF, "", -1)


# 表达式解析入口
func _parse_expression(state : ParseContext) -> FslASTNode:
	return _parse_ternary(state)


# 三元表达式解析
func _parse_ternary(state : ParseContext) -> FslASTNode:
	var condition: FslASTNode = _parse_logical_or(state)

	if current_token.type == FslToken.Type.QUESTION:
		_advance()  # 跳过 '?'
		var true_expr: FslASTNode = _parse_expression(state)

		if current_token.type != FslToken.Type.COLON:
			state.success = false;
			state.message = ("Expected ':' in ternary expression at position %d" % current_token.position);
			return null

		_advance()  # 跳过 ':'
		var false_expr: FslASTNode = _parse_ternary(state)
		if false_expr  == null:
			state.success = false;
			state.message = ("Expected expression after ':' in ternary expression at position %d" % current_token.position);
			return null

		return FSLTernaryExpression.new(condition, true_expr, false_expr)

	return condition


# 逻辑或
func _parse_logical_or(state : ParseContext) -> FslASTNode:
	var left: FslASTNode = _parse_logical_and(state)

	while current_token.type == FslToken.Type.OPERATOR and current_token.string_value == "||":
		var op: FslToken = current_token
		_advance()
		var right: FslASTNode = _parse_logical_and(state)
		left = FslBinaryExpression.new(op, left, right)

	return left


# 逻辑与
func _parse_logical_and(state : ParseContext) -> FslASTNode:
	var left: FslASTNode = _parse_equality(state)

	while current_token.type == FslToken.Type.OPERATOR and current_token.string_value == "&&":
		var op: FslToken = current_token
		_advance()
		var right: FslASTNode = _parse_equality(state)
		left = FslBinaryExpression.new(op, left, right)

	return left


# 相等性比较
func _parse_equality(state : ParseContext) -> FslASTNode:
	var left: FslASTNode = _parse_relational(state)

	while current_token.type == FslToken.Type.OPERATOR and current_token.string_value in ["==", "!="]:
		var op: FslToken = current_token
		_advance()
		var right: FslASTNode = _parse_relational(state)
		left = FslBinaryExpression.new(op, left, right)

	return left


# 关系比较
func _parse_relational(state : ParseContext) -> FslASTNode:
	var left: FslASTNode = _parse_additive(state)

	while current_token.type == FslToken.Type.OPERATOR and current_token.string_value in ["<", ">", "<=", ">="]:
		var op: FslToken = current_token
		_advance()
		var right: FslASTNode = _parse_additive(state)
		left = FslBinaryExpression.new(op, left, right)

	return left


# 加减表达式
func _parse_additive(state : ParseContext) -> FslASTNode:
	var left: FslASTNode = _parse_multiplicative(state)

	while current_token.type == FslToken.Type.OPERATOR and current_token.string_value in ["+", "-"]:
		var op: FslToken = current_token
		_advance()
		var right: FslASTNode = _parse_multiplicative(state)
		left = FslBinaryExpression.new(op, left, right)

	return left


# 乘除模表达式
func _parse_multiplicative(state : ParseContext) -> FslASTNode:
	var left: FslASTNode = _parse_exponent(state)

	while current_token.type == FslToken.Type.OPERATOR and current_token.string_value in ["*", "/", "%"]:
		var op: FslToken = current_token
		_advance()
		var right: FslASTNode = _parse_exponent(state)
		left = FslBinaryExpression.new(op, left, right)

	return left


# 指数表达式
func _parse_exponent(state : ParseContext) -> FslASTNode:
	var left: FslASTNode = _parse_unary(state)

	while current_token.type == FslToken.Type.OPERATOR and current_token.string_value == "**":
		var op: FslToken = current_token
		_advance()
		var right: FslASTNode = _parse_unary(state)
		left = FslBinaryExpression.new(op, left, right)

	return left


# 一元表达式
func _parse_unary(state : ParseContext) -> FslASTNode:
	if current_token.type == FslToken.Type.OPERATOR and current_token.string_value in ["+", "-", "!"]:
		var op: FslToken = current_token
		_advance()
		var expr: FslASTNode = _parse_unary(state)
		return FSLUnaryExpression.new(op, expr)

	return _parse_primary(state)


# 基础表达式
func _parse_primary(state : ParseContext) -> FslASTNode:
	var token: FslToken = current_token

	match token.type:
		FslToken.Type.IDENTIFIER:
			_advance()
			# 函数调用
			if current_token.type == FslToken.Type.LPAREN:
				if !(token.string_value in state.valid_functions): 
					state.success = false
					state.message = ("Unknown function '%s' at position %d" % [token.string_value, current_token.position])
					return null
				return _parse_function_call(token.string_value, state)

			# 普通变量
			if !(token.string_value in state.valid_variables):
				state.success = false
				state.message = ("Unknown variable '%s' at position %d" % [token.string_value, current_token.position])
				return null
				
			return FslIdentifierNode.new(token)

		FslToken.Type.NUMBER:
			_advance()
			return FslLiteralNode.new(token)

		FslToken.Type.LPAREN:
			_advance()  # 跳过 '('
			var expr: FslASTNode = _parse_expression(state)

			if current_token.type != FslToken.Type.RPAREN:
				state.success = false
				state.message = ("Expected ')' after expression at position %d" % current_token.position)
				return null

			_advance()  # 跳过 ')'
			return FslGroupExpression.new(expr)

		_:
			state.success = false
			state.message = ("Unexpected token at position %d: %s" % [token.position, token])
			return null


# 函数调用解析
func _parse_function_call(func_name: String, state : ParseContext) -> FslASTNode:
	_advance()  # 跳过 '('
	var args : Array[FslASTNode] = []

	# 处理参数列表
	if current_token.type != FslToken.Type.RPAREN:
		while true:
			args.append(_parse_expression(state))

			if current_token.type == FslToken.Type.RPAREN:
				break
			elif current_token.type == FslToken.Type.COMMA:
				_advance()
			else:
				state.success = false;
				state.message = ("Expected ',' or ')' in function arguments at position %d" % current_token.position)
				return null

	if current_token.type != FslToken.Type.RPAREN:
		state.success = false;
		state.message = ("Expected ')' after function arguments at position %d" % current_token.position)
		return null

	_advance()  # 跳过 ')'
	return FslFunctionCall.new(func_name, args)
