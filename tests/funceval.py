import re

class ExpressionEvaluator:
    def __init__(self):
        self.variables = {}
        self.functions = {'SUM': self.sum_function, 'SUB': self.sub_function,
                          'MUL': self.mul_function, 'DIV': self.div_function}
        self.string_variables = {}

    def evaluate(self, expression):
        tokens = expression.split()
        if '=' in tokens:
            return self.evaluate_assignment(tokens)
        else:
            return self.evaluate_expression(tokens)

    def evaluate_assignment(self, tokens):
        var_name = tokens[0]
        value = self.evaluate_expression(tokens[2:])
        self.variables[var_name] = value
        return f"Assigned {var_name} = {value}"

    def evaluate_expression(self, tokens):
        stack = []
        for token in tokens:
            if token.isdigit():
                stack.append(int(token))
            elif token.startswith('$'):
                stack.append(self.get_string_variable(token[1:]))
            elif token in self.variables:
                stack.append(self.variables[token])
            elif token in self.functions:
                func_result = self.functionstoken
                stack.append(func_result)
            elif token == '+':
                b, a = stack.pop(), stack.pop()
                stack.append(a + b)
            elif token == '-':
                b, a = stack.pop(), stack.pop()
                stack.append(a - b)
            # Add other operators (e.g., '*', '/') as needed
        return stack[0]

    def sum_function(self, stack):
        num_args = stack.pop()
        args = [stack.pop() for _ in range(num_args)]
        return sum(args)

    def sub_function(self, stack):
        result = stack.pop()
        while stack:
            result -= stack.pop()
        return result

    def mul_function(self, stack):
        result = 1
        while stack:
            result *= stack.pop()
        return result

    def div_function(self, stack):
        result = stack.pop()
        while stack:
            divisor = stack.pop()
            result //= divisor
        return result

    def get_string_variable(self, var_name):
        return self.string_variables.get(var_name, "")

    def set_string_variable(self, var_name, value):
        self.string_variables[var_name] = value

if __name__ == "__main__":
    evaluator = ExpressionEvaluator()
    expression1 = "VarA = VarB + 102"
    expression2 = "VarCat = VarDog - ABS(VarCat - CarDog) + 4"
    expression3 = "$StrVar = \"Test in quotes, \\\" embedded quote \\n\\tSecond Line is Tabbed\""

    result1 = evaluator.evaluate(expression1)
    result2 = evaluator.evaluate(expression2)
    result3 = evaluator.evaluate(expression3)

    print(result1)  # Example: Assigned VarA = 110
    print(result2)  # Example: Assigned VarCat = 8
    print(result3)  # Example: Assigned $StrVar = Test in quotes, " embedded quote \n\tSecond Line is Tabbed
