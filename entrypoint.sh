#!/usr/bin/env bash
set -euo pipefail

# entrypoint.sh — Sandflare GitHub Action entrypoint
# Runs SF_RUN command in a fresh Sandflare sandbox and streams output.

SANDFLARE_API_KEY="${SANDFLARE_API_KEY:-}"
SF_RUN="${SF_RUN:-}"
SF_TEMPLATE="${SF_TEMPLATE:-}"
SF_SIZE="${SF_SIZE:-small}"
SF_TIMEOUT="${SF_TIMEOUT:-300}"
SF_WORKDIR="${SF_WORKDIR:-/home/user}"
SF_UPLOAD_PATH="${SF_UPLOAD_PATH:-}"
SF_UPLOAD_REMOTE="${SF_UPLOAD_REMOTE:-/home/user/workspace}"
SF_KEEP="${SF_KEEP:-false}"

if [ -z "$SANDFLARE_API_KEY" ]; then
  echo "::error::SANDFLARE_API_KEY is not set"
  exit 1
fi

if [ -z "$SF_RUN" ]; then
  echo "::error::No 'run' input provided"
  exit 1
fi

echo "::group::Creating Sandflare sandbox"

# Build python one-liner to create sandbox and run
PYTHON_SCRIPT=$(cat <<'PYEOF'
import sys, os, json
from sandflare import Sandbox

api_key    = os.environ["SANDFLARE_API_KEY"]
template   = os.environ.get("SF_TEMPLATE", "")
size       = os.environ.get("SF_SIZE", "small")
timeout    = int(os.environ.get("SF_TIMEOUT", "300"))
workdir    = os.environ.get("SF_WORKDIR", "/home/user")
upload_src = os.environ.get("SF_UPLOAD_PATH", "")
upload_dst = os.environ.get("SF_UPLOAD_REMOTE", "/home/user/workspace")
keep       = os.environ.get("SF_KEEP", "false").lower() == "true"
cmd        = os.environ["SF_RUN"]

sb = Sandbox.create(
    label="github-action",
    template_id=template,
    size=size,
    api_key=api_key,
)

print(f"sandbox_id={sb.id}", flush=True)
print(f"::endgroup::", flush=True)

# Upload workspace files if requested
if upload_src:
    print(f"::group::Uploading {upload_src} → {upload_dst}")
    import os as _os
    if _os.path.isfile(upload_src):
        sb.upload(upload_src, upload_dst)
    elif _os.path.isdir(upload_src):
        result = sb.exec(f"mkdir -p {upload_dst}")
        for root, dirs, files in _os.walk(upload_src):
            for fname in files:
                local = _os.path.join(root, fname)
                rel = _os.path.relpath(local, upload_src)
                remote = _os.path.join(upload_dst, rel)
                sb.upload(local, remote)
    print("::endgroup::", flush=True)

# Execute the command, streaming output
print(f"::group::Running: {cmd}", flush=True)
exit_code = 0
try:
    for event in sb.stream(cmd, cwd=workdir, timeout=timeout):
        if event.event in ("stdout", "stderr"):
            print(event.line, end="", flush=True)
        elif event.event == "done":
            exit_code = event.exit_code or 0
except Exception as e:
    print(f"::error::Execution failed: {e}", flush=True)
    exit_code = 1

print(f"\n::endgroup::", flush=True)

# Write output
with open(os.environ.get("GITHUB_OUTPUT", "/dev/null"), "a") as f:
    f.write(f"exit_code={exit_code}\n")
    f.write(f"sandbox_id={sb.id}\n")

if not keep:
    sb.delete()
    print(f"Sandbox {sb.id} deleted.", flush=True)
else:
    print(f"Sandbox {sb.id} kept alive (keep_sandbox=true).", flush=True)

sys.exit(exit_code)
PYEOF
)

python3 -c "$PYTHON_SCRIPT"
