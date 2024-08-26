import math, re, time, sys

sqrt = lambda x : math.sqrt(x)
expt = lambda x, y : x**y
log  = lambda x : math.log(x)

ops = {
	#-----------------------------------------------#
	# symbol operators (can be infix if arity == 2) #
	#-----------------------------------------------#
	"+"     : {"precedence" : -3, "arity" :  2, "python": "args[0] + args[1]"          },
	"-"     : {"precedence" : -3, "arity" :  2, "python": "args[0] - args[1]"          },
	"*"     : {"precedence" : -2, "arity" :  2, "python": "args[0] * args[1]"          },
	"/"     : {"precedence" : -2, "arity" :  2, "python": "args[0] / args[1]"          },
	"//"    : {"precedence" : -2, "arity" :  2, "python": "args[0] // args[1]"         },
	"%"     : {"precedence" : -2, "arity" :  2, "python": "args[0] % args[1]"          },
	"**"    : {"precedence" : -1, "arity" :  2, "python": "args[0] ** args[1]"         },
	#--------------------------------#
	# fixed-arity function operators #
	#--------------------------------#
	"abs"   : {"precedence" :  0, "arity" :  1, "python": "abs(args[0])"               },
	"neg"   : {"precedence" :  0, "arity" :  1, "python": "-args[0]"                   },
	"inv"   : {"precedence" :  0, "arity" :  1, "python": "1/args[0]"                  },
	"mod"   : {"precedence" :  0, "arity" :  2, "python": "math.fmod(args[0], args[1])"},
	"pow"   : {"precedence" :  0, "arity" :  2, "python": "math.pow(args[0], args[1])" },
	"sqrt"  : {"precedence" :  0, "arity" :  1, "python": "math.sqrt(args[0])"         },
	"exp"   : {"precedence" :  0, "arity" :  1, "python": "math.exp(args[0])"          },
	"log"   : {"precedence" :  0, "arity" :  1, "python": "math.log(args[0])"          },
	"log10" : {"precedence" :  0, "arity" :  1, "python": "math.log10(args[0])"        },
	"sin"   : {"precedence" :  0, "arity" :  1, "python": "math.sin(args[0])"          },
	"cos"   : {"precedence" :  0, "arity" :  1, "python": "math.cos(args[0])"          },
	"tan"   : {"precedence" :  0, "arity" :  1, "python": "math.tan(args[0])"          },
	"asin"  : {"precedence" :  0, "arity" :  1, "python": "math.asin(args[0])"         },
	"acos"  : {"precedence" :  0, "arity" :  1, "python": "math.acos(args[0])"         },
	"atan"  : {"precedence" :  0, "arity" :  1, "python": "math.atan(args[0])"         },
	#----------------------------------------#
	# 0-arity function operators (CONSTANTS) #
	#----------------------------------------#
	"e"     : {"precedence" :  0, "arity" :  0, "python": "math.e"                     },
	"pi"    : {"precedence" :  0, "arity" :  0, "python": "math.pi"                    },
	#-----------------------------#
	# variadic function operators #
	#-----------------------------#
	"min"   : {"precedence" :  0, "arity" : -1, "python": "min(args)"                  },
	"max"   : {"precedence" :  0, "arity" : -1, "python": "max(args)"                  },
}
ops["^"   ] = ops["**"  ]
ops["ln"  ] = ops["log" ]
ops["logn"] = ops["log" ]
ops["expt"] = ops["pow" ] # lisp

op_tokens = ops.keys()
op_pattern = {}
op_replacement = {}
super_ops = []
sub_ops = {}
func_ops = []

for op in op_tokens:
	if op[0].isalnum() :
		#-------------------------------------#
		# function operator (cannot be infix) #
		#-------------------------------------#
		func_ops.append(op)
		pattern = "([\\W])(%s)([\\W])" % op
		op_pattern[op] = pattern
		op_replacement[op] = "\\1 \\2 \\3"
	else :
		#----------------------------------------------#
		# symbol operator (can be infix if arity == 2) #
		#----------------------------------------------#
		op_pattern[op] = "(%s)" % re.escape(op)
		op_replacement[op] = " \\1 "
	for op2 in op_tokens :
		if op2 != op and op.find(op2) != -1:
			if not op in super_ops : super_ops.append(op)
			if not op2 in sub_ops : sub_ops[op2] = []
			if not op in sub_ops[op2] : sub_ops[op2].append(op)

#-----------------------------------------#
# add replacements for grouping operators #
#-----------------------------------------#
for c in "(,)" : 
	op_pattern[c] = "(%s)" % re.escape(c)
	op_replacement[c] = " \\1 "

for c in "[{" :
	op_pattern[c] = "(%s)" % re.escape(c)
	op_replacement[c] = " ( "

for c in "]}" :
	op_pattern[c] = "(%s)" % re.escape(c)
	op_replacement[c] = " ) "

for key in op_pattern.keys() : op_pattern[key] = re.compile(op_pattern[key], re.IGNORECASE)

def parse_infix(expr):
	#-----------------------------------------------------------------------------#
	# pass 1 : expand all except operators that are substrings of other operators #
	#-----------------------------------------------------------------------------#
	for token in op_pattern.keys() :
		if token not in sub_ops :
			expr = op_pattern[token].sub(op_replacement[token], expr)
	parts = expr.split()
	#-----------------------------------------------------------------------#
	# pass 2 : expand the remaing operators (substrings of other operators) #
	#-----------------------------------------------------------------------#
	for i in range(len(parts)) :
		if parts[i] not in op_tokens + ["(", ",", ")"] :
			for token in sub_ops :
				parts[i] = op_pattern[token].sub(op_replacement[token], parts[i])
	parts = " ".join(parts).split()
	#---------------------------------#
	# pass 3 : unexpand unary + and - #
	#---------------------------------#
	for i in range(len(parts)-2, -1, -1) :
		if parts[i] in ("+", "-") :
			if i == 0 or parts[i-1] in op_tokens + ["(", ","] :
				if parts[i] == "-" :
					#--------------#
					# keep unary - #
					#--------------#
					parts[i:i+2] = ["".join(parts[i:i+2])]
				else :
					#-----------------#
					# discard unary + #
					#-----------------#
					parts[i:i+2] = [parts[i+1]]
	return parts
		
def infix_to_prefix(args) :
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = parse_infix(args)
		if tokens.count("(") != tokens.count(")"): 
			raise Exception("Unbalanced parentheses in expr: %s" % args)
		tokens.reverse()
	output_tokens = []
	stack = []
	i = 0
	while i < len(tokens) :
		token = tokens[i]
		if token == "(" :
			if i < len(tokens)-1 and tokens[i+1] in op_tokens and ops[tokens[i+1]]["arity"] == -1 :
				#---------------------------------------------------------#
				# opening paren of variadic function, must push arg count #
				#---------------------------------------------------------#
				arg_count = 1
				level = 1
				for j in range(i-1, -1, -1) :
					if tokens[j] == "(" :
						level += 1
					elif tokens[j] == ")" :
						level -= 1
						if level == 0 : break
					elif tokens[j] == "," and level == 1 :
						arg_count += 1
				i += 1
				stack.append(tokens[i])
				stack.append(repr(arg_count))
			while stack[-1] != ")" :
				output_tokens.append(stack.pop())
			stack.pop()
			i += 1
		elif token == ")" :
			stack.append(token)
			i += 1
		elif token == "," :
			i += 1
		elif token in op_tokens and ops[token]["arity"] != 0 :
			if  not stack or stack[-1] == ")" or ops[token]["precedence"] >= ops[stack[-1]]["precedence"] :
				stack.append(token)
				i += 1
			else :
				output_tokens.append(stack.pop())
		else :
			output_tokens.append(token)
			i += 1

	while stack :
		output_tokens.append(stack.pop())
		
	output_tokens.reverse()
	if type(args) == type("") :
		return " ".join(output_tokens)
	else :
		return output_tokens
		
def infix_to_postfix(args):
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = parse_infix(args)
		if tokens.count("(") != tokens.count(")"): 
			raise Exception("Unbalanced parentheses in expr: %s" % args)
	output_tokens = []
	stack = []
	i = 0
	while i < len(tokens) :
		token = tokens[i]
		if token == "(" :
			arg_count = 0
			if i > 0 and tokens[i-1] in op_tokens and ops[tokens[i-1]]["arity"] == -1 :
				#---------------------------------------------------------#
				# opening paren of variadic function, must push arg count #
				#---------------------------------------------------------#
				arg_count = 1
				level = 1
				for j in range(i+1, len(tokens)) :
					if tokens[j] == "(" :
						level += 1
					elif tokens[j] == ")" :
						level -= 1
						if level == 0 : break
					elif tokens[j] == "," and level == 1 :
						arg_count += 1
			stack.append(token)
			if arg_count : stack.append(repr(arg_count))
			i += 1
		elif token == ")" :
			while stack[-1] != "(" :
				output_tokens.append(stack.pop())
			stack.pop()
			if stack and stack[-1] in op_tokens and ops[stack[-1]]["arity"] == -1 :
				output_tokens.append(stack.pop())
			i += 1
		elif token == "," :
			i += 1
		elif token in op_tokens and ops[token]["arity"] != 0:
			if not stack or stack[-1] not in op_tokens or ops[token]["precedence"] > ops[stack[-1]]["precedence"] :
				stack.append(token)
				i += 1
			else :
				output_tokens.append(stack.pop())
		else :
			output_tokens.append(token)
			i += 1
			
	while stack :
		output_tokens.append(stack.pop())
		
	if type(args) == type("") :
		return " ".join(output_tokens)
	else :
		return output_tokens

def infix_to_tree(args) :
	return prefix_to_tree(infix_to_prefix(args))
	
def prefix_to_tree(args) :
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = args.split()

	def make_node(op, stack) :
		node = [op, []]
		arity = ops[op]["arity"]
		if arity < 0 : arity = int(stack.pop(0))
		for i in range(arity) :
			if stack[0] in op_tokens and ops[stack[0]]["arity"] != 0 :
				node[1].append(make_node(stack.pop(0), stack))
			else :
				node[1].append(stack.pop(0))
		return node

	return make_node(tokens.pop(0), tokens)
	
def postfix_to_tree(args):
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = args.split()
		
	def make_node(op, stack) :
		node = [op, []]
		arity = ops[op]["arity"]
		if arity < 0 : arity = int(stack.pop())
		for i in range(arity) :
			if stack[-1] in op_tokens and ops[stack[-1]]["arity"] != 0 :
				node[1].insert(0, make_node(stack.pop(), stack))
			else :
				node[1].insert(0, stack.pop())
		return node

	return make_node(tokens.pop(), tokens)

def compute_tree(tree) :
	op, _args = tree
	args = _args[:]
	for i in range(len(args)) :
		if type(args[i]) == type([]) : 
			args[i] = compute_tree(args[i])
		elif args[i] in op_tokens and ops[args[i]]["arity"] == 0 :
			args[i] = eval(ops[args[i]]["python"])
	args = list(map(float, args))
	return eval(ops[op]["python"])

def compute_prefix(args):
	return compute_tree(prefix_to_tree(args))
		
def compute_infix(args) :
	if type(args) == type([]) :
		eqn = " ".join(args)
	elif type(args) == type("") : 
		eqn = args
	return eval(eqn)
	
def compute_postfix(args) :
	return compute_tree(postfix_to_tree(args))

def tree_to_prefix(tree) :
	op, args = tree
	tokens = []
	tokens.append(op)
	for arg in args :
		if type(arg) == type ([]) :
			tokens.extend(tree_to_prefix(arg))
		else :
			tokens.append(arg)
	return tokens

def tree_to_infix(tree) :
	op, args = tree
	tokens = []
	if op not in func_ops and ops[op]["arity"] == 2 :
		#-----------------------#
		# infix symbol operator #
		#-----------------------#
		#---------------#
		# first operand #
		#---------------#
		if type(args[0]) == type ([]) :
			parenthesize =  ops[args[0][0]]["precedence"] < ops[op]["precedence"]
			if parenthesize : tokens.append("(")
			tokens.extend(tree_to_infix(args[0]))
			if parenthesize : tokens.append(")")
		else :
			tokens.append(args[0])
		#----------------------------#			
		# operator in infix position #
		#----------------------------#			
		tokens.append(op)
		#----------------#
		# second operand #
		#----------------#
		if type(args[1]) == type ([]) :
			parenthesize =  ops[args[1][0]]["precedence"] < ops[op]["precedence"]
			if parenthesize : tokens.append("(")
			tokens.extend(tree_to_infix(args[1]))
			if parenthesize : tokens.append(")")
		else :
			tokens.append(args[1])
	else :
		#----------------------------------------#
		# other operator, put in prefix position #
		#----------------------------------------#
		tokens.extend([op, "("])
		for i in range(len(args)) :
			if type(args[i]) == type ([]) :
				tokens.extend(tree_to_infix(args[i]))
			else :
				tokens.append(args[i])
			if i < len(args)-1 :
				tokens.append(",")
			
		tokens.append(")")
	return tokens

def tree_to_postfix(tree) :
	op, args = tree
	tokens = []
	for arg in args :
		if type(arg) == type ([]) :
			tokens.extend(tree_to_postfix(arg))
		else :
			tokens.append(arg)
	tokens.append(op)
	return tokens

def lisp_to_prefix(args):
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = args.replace("(", " ( ").replace(")", " ) ").split()

	output_tokens = []
	for i in range(len(tokens)) :
		if tokens[i] in op_tokens and ops[tokens[i]]["arity"] < 0 :
			arg_count = 0
			level = 1
			for j in range(i+1, len(tokens)) :
				if tokens[j] == "(" :
					if level == 1 : arg_count += 1
					level += 1
				elif tokens[j] == ")" :
					level -= 1
					if level == 0 : break
				elif level == 1 :
					arg_count += 1
			output_tokens.extend([tokens[i], repr(arg_count)])
			
		elif tokens[i] not in ("(", ")") : output_tokens.append(tokens[i])
		
	if type(args) == type("") :
		return " ".join(output_tokens)
	else :
		return output_tokens

def prefix_to_lisp(args) :
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = args.split()

	output_tokens = tokens[:]
	output_tokens.reverse()
	
	def parse_prefix_expr(tokens) :
		stack = []
		op = tokens.pop()
		assert op in op_tokens
		arity = ops[op]["arity"]
		if arity < 0 : arity = int(tokens.pop())
		for i in range(arity) :
			if tokens[-1] in op_tokens :
				stack.append(parse_prefix_expr(tokens))
			else :
				stack.append(tokens.pop())
		if arity == 0 :
			return op
		else :
			return "(%s %s)" % (op, " ".join(map(str, stack)))

	output_tokens = parse_prefix_expr(output_tokens).split()
	
	if type(args) == type("") :
		return " ".join(output_tokens)
	else :
		return output_tokens
		
def prefix_to_infix(args) :
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = args.split()

	output_tokens = tree_to_infix(prefix_to_tree(tokens))
	
	if type(args) == type("") :
		return " ".join(output_tokens)
	else :
		return output_tokens
		
def postfix_to_infix(args) :
	if type(args) == type([]) :
		tokens = args
	elif type(args) == type("") : 
		tokens = args.split()

	output_tokens = tree_to_infix(postfix_to_tree(tokens))
	
	if type(args) == type("") :
		return " ".join(output_tokens)
	else :
		return output_tokens

class Computation :

	def __init__(self, expr="", cond=""):
		self.expr_stack = []
		self.compute_tree = None
		self.reset_expr(expr)
		self.reset_cond(cond)

	def convert_rma_expression_format(self, _expr) :
		expr = _expr.replace("|", " ")
		expr = re.compile("(^|\s+)ARG\s+(\d+\s)", re.IGNORECASE).sub("$\\2", expr)
		return expr
		
	def reset_expr(self, expr, _notation=None):
		expr = self.convert_rma_expression_format(expr.strip())
		tokens = expr.lower().split()
		if _notation is None :
			if expr[0] == '(' and expr[-1] == ')' :
				notation = "lisp"
			elif tokens[0] in op_tokens :
				notation = "prefix"
			elif tokens[-1] in op_tokens :
				notation = "postfix"
			else :
				notation = "infix"
		else :
			notation = _notation.lower()
		if notation == "infix" : 
			self.compute_tree = infix_to_tree(expr)
		elif notation in ["prefix", "polish"] : 
			self.compute_tree = prefix_to_tree(expr)
		elif notation in ["postfix", "reverse polish", "rpn"] : 
			self.compute_tree = postfix_to_tree(expr)
		elif notation == "lisp" :
			self.compute_tree = prefix_to_tree(lisp_to_prefix(expr))
		else :
			raise Exception("Invalid notation format: %s" % _notation)

		self.var_locations = {}
		def process_node(node, global_index="") :
			for i in range(len(node)) :
				node_index = "%s[%d]" % (global_index, i)
				if type(node[i]) == type("") :
					try : 
						node[i] = float(node[i])
					except : 
						if node[i][0] == '$':
							self.var_locations.setdefault(node[i], []).append(node_index)
				else :
					process_node(node[i], node_index)

		process_node(self.compute_tree)					

	def reset_cond(self, cond):
		pass

	def to_string(self, _notation="infix", with_values=False) :
		if not with_values :
			expected_vars = self.var_locations.keys()
			for expected_var in expected_vars :
				cmd = "self.compute_tree%s = '%s'" % (self.var_locations[expected_var], expected_var)
				exec (cmd)
				
		notation = _notation.lower()
		if notation == "infix" : 
			return " ".join(map(str, tree_to_infix(self.compute_tree)))
		elif notation in ["prefix", "polish"] : 
			return " ".join(map(str, tree_to_prefix(self.compute_tree)))
		elif notation in ["postfix", "reverse polish", "rpn"] : 
			return " ".join(map(str, tree_to_postfix(self.compute_tree)))
		elif notation == "lisp" :
			return " ".join(map(str, prefix_to_lisp(tree_to_prefix(self.compute_tree))))
		elif notation == "tree" :
			print(self.compute_tree)
		else :
			raise Exception("Invalid notation format: %s" % _notation)

	def set_values(self, _values, _names):
		if type(_values) in (type(()), type([])):
			values = _values
		else :
			values = [_values]
		if type(_names) in (type(()), type([])):
			names = _names
		else :
			names = [_names]
		vars = {}
		for i in range(len(names)) : vars[names[i]] = i

		expected_vars = self.var_locations.keys()
		for expected_var in expected_vars :
			name = expected_var[1:]
			if name.isdigit() :
				value = values[int(name)]
			else :
				value = values[vars[name]]
			for loc in self.var_locations[expected_var] :
				cmd = "self.compute_tree%s = %f" % (loc, value)
				exec (cmd)
		
	def compute(self, _values, _names=[]):
		self.set_values(_values, _names)
		return compute_tree(self.compute_tree)
		
if __name__ == "__main__" :
	f2c = Computation("($temp_f-32)/1.8")
	c2f = Computation("$temp_c*1.8+32")
	temps = [-40, 0, 32, 37, 98.6, 100, 212]
	
	for temp in temps :
		print("%f F = %f C" % (temp, f2c.compute(temp, "temp_f")))
		print("%f C = %f F" % (temp, c2f.compute(temp, "temp_c")))
		print()
	
	# expr = "2.0/3.0+(4.0-5.0)*4.0"	
	expr = "$0-[2.1/sqrt(3.2)]*$1+(pow({logn[13.0/log10(2.3)]},(-1.3/2.7)))"
	expr = "2*$0*$1-(2.1/sqrt(3.2))*$1+(-3.7*((5*logn(13.0/2*log10(2.3)))^(-1.3/2.7)))"
	# expr = "2*pi/max(+2,min(-3, 6),-4) // 1"
	
	print("Infix (Original) = %s" % expr)
	print("Infix (Parsed)   = %s" % " ".join(parse_infix(expr)))
	
	postfix = infix_to_postfix(expr)
	prefix  = infix_to_prefix(expr)
	print("Infix   -> Postfix = %s" % postfix)
	print("Infix   -> Prefix  = %s" % prefix)
	lisp    = prefix_to_lisp(infix_to_prefix(expr))
	
	print("Infix   -> Lisp    = %s" % lisp)
	
	print("Postfix -> Infix   = %s" % postfix_to_infix(postfix))
	print("Prefix  -> Infix   = %s" % prefix_to_infix(prefix))
	print("Lisp    -> Infix   = %s" % prefix_to_infix(lisp_to_prefix(lisp)))
	
	comp = Computation(expr)
	
	for i in range(len(temps)) :
		args = [temps[i], temps[(i+3)%len(temps)]]
		print("%s = %s" % (args, comp.compute(args)))
