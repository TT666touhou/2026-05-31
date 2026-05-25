import ast
with open('ragdoll_controller.gd', 'r', encoding='utf-8') as f:
    content = f.read().strip()
if content.startswith("'") and content.endswith("'"):
    content = content[1:-1]
if content.startswith('"') and content.endswith('"'):
    content = ast.literal_eval(content)
    with open('ragdoll_controller.gd', 'w', encoding='utf-8') as fo:
        fo.write(content)
print("Fixed ragdoll")
