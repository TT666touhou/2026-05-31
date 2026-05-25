import json
with open(r'C:\Users\88698\.gemini\antigravity-ide\brain\5256423d-c964-4269-8853-f9607cd814f9\.system_generated\logs\transcript.jsonl', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for line in reversed(lines):
    try:
        data = json.loads(line)
        if 'tool_calls' in data:
            for tc in data['tool_calls']:
                if tc['name'] == 'write_to_file':
                    args = tc.get('args', {})
                    if 'ragdoll_controller.gd' in args.get('TargetFile', ''):
                        content = args['CodeContent']
                        with open('ragdoll_controller.gd', 'w', encoding='utf-8') as out:
                            out.write(content)
                        print("Successfully restored ragdoll_controller.gd from JSON!")
                        exit(0)
    except Exception as e:
        pass
print("Failed to find it")
