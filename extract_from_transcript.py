import json
import os

transcript_path = r"C:\Users\88698\.gemini\antigravity-ide\brain\5256423d-c964-4269-8853-f9607cd814f9\.system_generated\logs\transcript.jsonl"
target_files = ['Main.gd', 'player_controller.gd', 'procedural_drawer.gd', 'ragdoll_controller.gd', 'verify_movement.gd', 'build_tilemap.gd']
file_contents = {f: None for f in target_files}

# Since we want the latest full content, we should look for write_to_file or replace_file_content or view_file output.
# Actually, the simplest way is to look for when the files were viewed or written.
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            step = json.loads(line)
        except:
            continue
            
        if 'tool_calls' in step:
            for tc in step['tool_calls']:
                if tc['name'] == 'write_to_file':
                    args = tc.get('args', {})
                    if 'TargetFile' in args and 'CodeContent' in args:
                        for target in target_files:
                            if target in args['TargetFile']:
                                file_contents[target] = args['CodeContent']
                                print(f"Found CodeContent for {target}")
                                
        # For view_file, we might get the content in the response.
        if step.get('type') == 'PLANNER_RESPONSE' and step.get('status') == 'DONE':
            pass
            
# Write them out!
out_dir = r"C:\Users\88698\Documents\2026.05.24"
for fname, content in file_contents.items():
    if content:
        with open(os.path.join(out_dir, fname), 'w', encoding='utf-8') as out_f:
            out_f.write(content)
        print(f"Restored {fname}")
    else:
        print(f"Could not find {fname} in write_to_file history. Need deeper search.")
