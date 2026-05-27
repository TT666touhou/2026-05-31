import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";
import { readdir, stat } from "fs/promises";
import { join, extname } from "path";
import { mkdirSync, existsSync } from "fs";

// ─── Configuration ─────────────────────────────────────────────────────────
const GODOT_EXE =
  "C:\\Users\\88698\\Downloads\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64.exe";
const PROJECT_PATH = "C:\\Users\\88698\\Documents\\2026.05.24";
const SCREENSHOTS_DIR = join(PROJECT_PATH, ".mcp", "screenshots");

// Ensure screenshots directory exists
if (!existsSync(SCREENSHOTS_DIR)) {
  mkdirSync(SCREENSHOTS_DIR, { recursive: true });
}

// ─── Helper: run a command and capture output ───────────────────────────────
function runCommand(exe, args, timeoutMs = 30000) {
  return new Promise((resolve) => {
    const proc = spawn(exe, args, { cwd: PROJECT_PATH });
    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (d) => (stdout += d.toString()));
    proc.stderr.on("data", (d) => (stderr += d.toString()));

    const timer = setTimeout(() => {
      proc.kill();
      resolve({ stdout, stderr, code: -1, timedOut: true });
    }, timeoutMs);

    proc.on("close", (code) => {
      clearTimeout(timer);
      resolve({ stdout, stderr, code, timedOut: false });
    });
  });
}

// ─── Helper: recursively find files with extension ──────────────────────────
async function findFiles(dir, ext, results = []) {
  let entries;
  try {
    entries = await readdir(dir);
  } catch {
    return results;
  }
  for (const entry of entries) {
    if (entry.startsWith(".") || entry === "node_modules" || entry === "addons") continue;
    const full = join(dir, entry);
    const info = await stat(full).catch(() => null);
    if (!info) continue;
    if (info.isDirectory()) {
      await findFiles(full, ext, results);
    } else if (extname(entry) === ext) {
      results.push(full.replace(PROJECT_PATH + "\\", "res://").replace(/\\/g, "/"));
    }
  }
  return results;
}

// ─── Parse GUT output ───────────────────────────────────────────────────────
function parseGutOutput(stdout, stderr) {
  const combined = stdout + stderr;
  const passed = (combined.match(/passed/gi) || []).length;
  const failed = (combined.match(/failed/gi) || []).length;
  const errors = [];
  for (const line of combined.split("\n")) {
    if (line.includes("FAILED") || line.includes("ERROR") || line.includes("error")) {
      errors.push(line.trim());
    }
  }
  return { passed, failed, errors: errors.filter(Boolean), raw: combined.slice(0, 2000) };
}

// ─── Parse GDScript validation output ──────────────────────────────────────
function parseGdscriptErrors(stderr) {
  const errors = [];
  for (const line of stderr.split("\n")) {
    const m = line.match(/(\d+):(\d+): (.+)/);
    if (m) errors.push({ line: parseInt(m[1]), col: parseInt(m[2]), message: m[3].trim() });
  }
  return errors;
}

// ─── Tool Definitions ───────────────────────────────────────────────────────
const TOOLS = [
  {
    name: "run_gut_tests",
    description:
      "Execute Godot GUT unit tests in headless mode. Returns JSON with passed/failed counts and error messages.",
    inputSchema: {
      type: "object",
      properties: {
        test_file: {
          type: "string",
          description:
            "Optional: specific test file path (res:// format). If omitted, runs all tests in res://tests/unit/",
        },
      },
    },
  },
  {
    name: "capture_scene_screenshot",
    description:
      "Run a scene in headless Godot, wait N seconds, then capture a screenshot. Returns the saved image path.",
    inputSchema: {
      type: "object",
      required: ["scene_path"],
      properties: {
        scene_path: {
          type: "string",
          description: "Scene path in res:// format, e.g. res://src/world/cave_01/CaveLevel.tscn",
        },
        wait_seconds: {
          type: "number",
          default: 2.0,
          description: "How many seconds to wait before screenshot (default: 2)",
        },
      },
    },
  },
  {
    name: "validate_gdscript",
    description:
      "Validate GDScript syntax using Godot --check-only. Returns validation result and any errors.",
    inputSchema: {
      type: "object",
      required: ["file_path"],
      properties: {
        file_path: {
          type: "string",
          description: "Absolute path or res:// path to the .gd file to validate",
        },
      },
    },
  },
  {
    name: "list_project_scenes",
    description: "List all .tscn scene files in the Godot project. Returns array of res:// paths.",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
];

// ─── Tool Handlers ──────────────────────────────────────────────────────────
async function handleRunGutTests(args) {
  const gutScript = join(PROJECT_PATH, "addons", "gut", "gut_cmdln.gd");
  const testDir = args.test_file || "res://tests/unit/";

  const godotArgs = [
    "--headless",
    "--path",
    PROJECT_PATH,
    "-s",
    "res://addons/gut/gut_cmdln.gd",
    `-gdir=${testDir.includes("res://") ? testDir : "res://tests/unit/"}`,
    "-gexit",
    "-glog=1",
  ];

  if (args.test_file) {
    godotArgs.push(`-gtest=${args.test_file}`);
  }

  const result = await runCommand(GODOT_EXE, godotArgs, 60000);
  const parsed = parseGutOutput(result.stdout, result.stderr);

  return {
    success: parsed.failed === 0,
    passed: parsed.passed,
    failed: parsed.failed,
    errors: parsed.errors,
    raw_output: parsed.raw,
    timed_out: result.timedOut,
  };
}

async function handleCaptureScreenshot(args) {
  const timestamp = Date.now();
  const screenshotPath = join(SCREENSHOTS_DIR, `scene_${timestamp}.png`);
  const resScreenshotPath = `res://.mcp/screenshots/scene_${timestamp}.png`;
  const waitSec = args.wait_seconds ?? 2.0;

  // Inject a screenshot script
  const screenshotScript = `
extends SceneTree
func _init():
    var t := Timer.new()
    t.wait_time = ${waitSec}
    t.one_shot = true
    root.add_child(t)
    t.start()
    await t.timeout
    var img := get_viewport().get_texture().get_image()
    img.save_png("${screenshotPath.replace(/\\/g, "/")}")
    quit()
`;

  const scriptPath = join(SCREENSHOTS_DIR, `capture_${timestamp}.gd`);
  const { writeFileSync } = await import("fs");
  writeFileSync(scriptPath, screenshotScript);

  const godotArgs = [
    "--headless",
    "--path",
    PROJECT_PATH,
    args.scene_path,
    "--script",
    scriptPath,
  ];

  const result = await runCommand(GODOT_EXE, godotArgs, 30000);

  return {
    success: result.code === 0 || existsSync(screenshotPath),
    screenshot_path: screenshotPath,
    res_path: resScreenshotPath,
    stderr: result.stderr.slice(0, 500),
    timed_out: result.timedOut,
  };
}

async function handleValidateGdscript(args) {
  let filePath = args.file_path;
  if (filePath.startsWith("res://")) {
    filePath = join(PROJECT_PATH, filePath.replace("res://", "").replace(/\//g, "\\"));
  }

  const godotArgs = [
    "--headless",
    "--path",
    PROJECT_PATH,
    "--check-only",
    "-s",
    filePath,
  ];

  const result = await runCommand(GODOT_EXE, godotArgs, 15000);
  const errors = parseGdscriptErrors(result.stderr);
  const valid = errors.length === 0 && result.code === 0;

  return {
    valid,
    file: args.file_path,
    error_count: errors.length,
    errors,
    raw_stderr: result.stderr.slice(0, 1000),
  };
}

async function handleListProjectScenes() {
  const scenes = await findFiles(PROJECT_PATH, ".tscn");
  return { scenes, count: scenes.length };
}

// ─── MCP Server Setup ───────────────────────────────────────────────────────
const server = new Server(
  { name: "godot-studio", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;
    switch (name) {
      case "run_gut_tests":
        result = await handleRunGutTests(args ?? {});
        break;
      case "capture_scene_screenshot":
        result = await handleCaptureScreenshot(args ?? {});
        break;
      case "validate_gdscript":
        result = await handleValidateGdscript(args ?? {});
        break;
      case "list_project_scenes":
        result = await handleListProjectScenes();
        break;
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  } catch (err) {
    return {
      content: [{ type: "text", text: JSON.stringify({ error: err.message }) }],
      isError: true,
    };
  }
});

// ─── Start ──────────────────────────────────────────────────────────────────
const transport = new StdioServerTransport();
await server.connect(transport);
console.error("✅ Godot Studio MCP Server running (stdio)");
