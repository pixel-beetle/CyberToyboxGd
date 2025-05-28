class_name FunctionExpressionParser

# Token类型枚举
enum TokenType {
	IDENTIFIER,
	NUMBER,
	OPERATOR,
	LPAREN,
	RPAREN,
	COMMA,
	QUESTION,
	COLON,
	EOF
}

# AST节点类型
enum NodeType {
	BINARY_OP,
	UNARY_OP,
	FUNCTION_CALL,
	VARIABLE,
	LITERAL,
	TERNARY,
	GROUP
}

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

# Token模式定义（正则表达式）
const TOKEN_PATTERNS: Array[Variant] = [
					   # 运算符（双字符优先）
						   {"regex": "^\\*\\*", "type": TokenType.OPERATOR, "value": "**"},
						   {"regex": "^&&", "type": TokenType.OPERATOR, "value": "&&"},
						   {"regex": "^\\|\\|", "type": TokenType.OPERATOR, "value": "||"},
						   {"regex": "^==", "type": TokenType.OPERATOR, "value": "=="},
						   {"regex": "^!=", "type": TokenType.OPERATOR, "value": "!="},
						   {"regex": "^<=", "type": TokenType.OPERATOR, "value": "<="},
						   {"regex": "^>=", "type": TokenType.OPERATOR, "value": ">="},
						   {"regex": "^[+\\-*/%<>=!&|^~]", "type": TokenType.OPERATOR},

					   # 数字字面量
						   {"regex": "^\\d+\\.\\d*([eE][\\-+]?\\d+)?", "type": TokenType.NUMBER}, # 浮点数
						   {"regex": "^\\.\\d+([eE][\\-+]?\\d+)?", "type": TokenType.NUMBER},     # .开头浮点数
						   {"regex": "^\\d+[eE][\\-+]?\\d+", "type": TokenType.NUMBER},           # 科学计数法
						   {"regex": "^\\d+", "type": TokenType.NUMBER},                           # 整数

					   # 标识符
						   {"regex": "^[a-zA-Z_][a-zA-Z0-9_]*", "type": TokenType.IDENTIFIER},

					   # 标点符号
						   {"regex": "^\\(", "type": TokenType.LPAREN, "value": "("},
						   {"regex": "^\\)", "type": TokenType.RPAREN, "value": ")"},
						   {"regex": "^,", "type": TokenType.COMMA, "value": ","},
						   {"regex": "^\\?", "type": TokenType.QUESTION, "value": "?"},
						   {"regex": "^:", "type": TokenType.COLON, "value": ":"},
					   ]

# Token类
class Token:
	var type: int
	var value
	var position: int

	func _init(t: int, v, pos: int):
		type = t
		value = v
		position = pos

	func _to_string() -> String:
		return "[%s: %s]" % [TokenType.keys()[type], value]

# AST节点基类
class ASTNode:
	var type: int
	var children = []

	func _init(t: int, c = []):
		type = t
		children = c

	func _to_string() -> String:
		return _str_indent(0)

	func _str_indent(indent: int) -> String:
		var s: String = "%s%s" % ["  ".repeat(indent), NodeType.keys()[type]]
		for child in children:
			if child is ASTNode:
				s += "\n" + child._str_indent(indent + 1)
			else:
				s += "\n%s%s" % ["  ".repeat(indent + 1), str(child)]
		return s

# 解析器主体
var tokens: Array
var current_token: Token
var position: int = 0

# 主解析函数
func parse(expression: String) -> ASTNode:
	tokens = _tokenize(expression)
	if tokens.size() == 0:
		return null
	position = 0
	current_token = tokens[0]
	return _parse_expression()

# 正则表达式词法分析器
func _tokenize(expression: String) -> Array:
	var tokens = []
	var pos: int = 0
	var length: int = expression.length()

	while pos < length:
		var substr: String = expression.substr(pos)

		# 跳过空白字符
		if substr.begins_with(" ") or substr.begins_with("\t") or substr.begins_with("\n") or substr.begins_with("\r"):
			pos += 1
			continue

		var matched: bool = false

		# 尝试匹配所有token模式
		for pattern in TOKEN_PATTERNS:
			var regex = RegEx.new()
			var err = regex.compile(pattern.regex)
			if err != OK:
				push_error("Regex compilation error: " + pattern.regex)
				continue

			var result = regex.search(substr)
			if result:
				# 提取匹配值
				var value = pattern.get("value", result.get_string())

				# 处理数字类型转换
				if pattern.type == TokenType.NUMBER:
					if value is String:
						if value.contains(".") or value.to_lower().contains("e"):
							value = value.to_float()
						else:
							value = value.to_int()

				# 创建token
				tokens.append(Token.new(pattern.type, value, pos))
				pos += result.get_string().length()
				matched = true
				break

		# 未匹配任何token模式
		if not matched:
			push_error("Unexpected character at position %d: '%s'" % [pos, expression[pos]])
			return []

	tokens.append(Token.new(TokenType.EOF, null, pos))
	return tokens

# 获取下一个token
func _advance():
	position += 1
	if position < tokens.size():
		current_token = tokens[position]
	else:
		current_token = Token.new(TokenType.EOF, null, -1)

# 表达式解析入口
func _parse_expression() -> ASTNode:
	return _parse_ternary()

# 三元表达式解析
func _parse_ternary() -> ASTNode:
	var condition: ASTNode = _parse_logical_or()

	if current_token.type == TokenType.QUESTION:
		_advance()  # 跳过 '?'
		var true_expr: ASTNode = _parse_expression()

		if current_token.type != TokenType.COLON:
			push_error("Expected ':' in ternary expression at position %d" % current_token.position)
			return null

		_advance()  # 跳过 ':'
		var false_expr: ASTNode = _parse_ternary()

		return ASTNode.new(NodeType.TERNARY, [condition, true_expr, false_expr])

	return condition

# 逻辑或
func _parse_logical_or() -> ASTNode:
	var left: ASTNode = _parse_logical_and()

	while current_token.type == TokenType.OPERATOR and current_token.value == "||":
		var op: Token = current_token
		_advance()
		var right: ASTNode = _parse_logical_and()
		left = ASTNode.new(NodeType.BINARY_OP, [op.value, left, right])

	return left

# 逻辑与
func _parse_logical_and() -> ASTNode:
	var left: ASTNode = _parse_equality()

	while current_token.type == TokenType.OPERATOR and current_token.value == "&&":
		var op: Token = current_token
		_advance()
		var right: ASTNode = _parse_equality()
		left = ASTNode.new(NodeType.BINARY_OP, [op.value, left, right])

	return left

# 相等性比较
func _parse_equality() -> ASTNode:
	var left: ASTNode = _parse_relational()

	while current_token.type == TokenType.OPERATOR and current_token.value in ["==", "!="]:
		var op: Token = current_token
		_advance()
		var right: ASTNode = _parse_relational()
		left = ASTNode.new(NodeType.BINARY_OP, [op.value, left, right])

	return left

# 关系比较
func _parse_relational() -> ASTNode:
	var left: ASTNode = _parse_additive()

	while current_token.type == TokenType.OPERATOR and current_token.value in ["<", ">", "<=", ">="]:
		var op: Token = current_token
		_advance()
		var right: ASTNode = _parse_additive()
		left = ASTNode.new(NodeType.BINARY_OP, [op.value, left, right])

	return left

# 加减表达式
func _parse_additive() -> ASTNode:
	var left: ASTNode = _parse_multiplicative()

	while current_token.type == TokenType.OPERATOR and current_token.value in ["+", "-"]:
		var op: Token = current_token
		_advance()
		var right: ASTNode = _parse_multiplicative()
		left = ASTNode.new(NodeType.BINARY_OP, [op.value, left, right])

	return left

# 乘除模表达式
func _parse_multiplicative() -> ASTNode:
	var left: ASTNode = _parse_exponent()

	while current_token.type == TokenType.OPERATOR and current_token.value in ["*", "/", "%"]:
		var op: Token = current_token
		_advance()
		var right: ASTNode = _parse_exponent()
		left = ASTNode.new(NodeType.BINARY_OP, [op.value, left, right])

	return left

# 指数表达式
func _parse_exponent() -> ASTNode:
	var left: ASTNode = _parse_unary()

	while current_token.type == TokenType.OPERATOR and current_token.value == "**":
		var op: Token = current_token
		_advance()
		var right: ASTNode = _parse_unary()
		left = ASTNode.new(NodeType.BINARY_OP, [op.value, left, right])

	return left

# 一元表达式
func _parse_unary() -> ASTNode:
	if current_token.type == TokenType.OPERATOR and current_token.value in ["+", "-", "!"]:
		var op = current_token.value
		_advance()
		var expr: ASTNode = _parse_unary()
		return ASTNode.new(NodeType.UNARY_OP, [op, expr])

	return _parse_primary()

# 基础表达式
func _parse_primary() -> ASTNode:
	var token: Token = current_token

	match token.type:
		TokenType.IDENTIFIER:
			_advance()

			# 函数调用
			if current_token.type == TokenType.LPAREN:
				return _parse_function_call(token.value)

			# 普通变量
			return ASTNode.new(NodeType.VARIABLE, [token.value])

		TokenType.NUMBER:
			_advance()
			return ASTNode.new(NodeType.LITERAL, [token.value])

		TokenType.LPAREN:
			_advance()  # 跳过 '('
			var expr: ASTNode = _parse_expression()

			if current_token.type != TokenType.RPAREN:
				push_error("Expected ')' after expression at position %d" % current_token.position)
				return null

			_advance()  # 跳过 ')'
			return ASTNode.new(NodeType.GROUP, [expr])

		_:
			push_error("Unexpected token at position %d: %s" % [token.position, token])
			return null

# 函数调用解析
func _parse_function_call(func_name: String) -> ASTNode:
	_advance()  # 跳过 '('
	var args = []

	# 处理参数列表
	if current_token.type != TokenType.RPAREN:
		while true:
			args.append(_parse_expression())

			if current_token.type == TokenType.RPAREN:
				break
			elif current_token.type == TokenType.COMMA:
				_advance()
			else:
				push_error("Expected ',' or ')' in function arguments at position %d" % current_token.position)
				return null

	if current_token.type != TokenType.RPAREN:
		push_error("Expected ')' after function arguments at position %d" % current_token.position)
		return null

	_advance()  # 跳过 ')'
	return ASTNode.new(NodeType.FUNCTION_CALL, [func_name] + args)

# 错误处理
func push_error(message: String):
	print("GLSL Parser Error: ", message)
