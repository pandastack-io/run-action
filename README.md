# Sandflare Sandbox Run — GitHub Action

Run any command in an **isolated Firecracker microVM** from your CI pipeline using [Sandflare](https://sandflare.io).

Each workflow step gets a fresh, ephemeral sandbox — no shared state, no container escape risk, 50ms cold-start from snapshot.

## Usage

### Basic

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: pandastack-io/run-action@v1
    with:
      api_key: ${{ secrets.SANDFLARE_API_KEY }}
      run: python eval_agent.py
```

### With template and VM size

```yaml
  - uses: pandastack-io/run-action@v1
    with:
      api_key: ${{ secrets.SANDFLARE_API_KEY }}
      template: code-interpreter
      size: medium
      run: python run_evals.py
```

### Upload files, then run

```yaml
  - uses: pandastack-io/run-action@v1
    with:
      api_key: ${{ secrets.SANDFLARE_API_KEY }}
      upload_path: ./tests
      upload_remote_path: /home/user/tests
      run: cd /home/user/tests && python -m pytest
```

### Keep sandbox alive for debugging

```yaml
  - uses: pandastack-io/run-action@v1
    with:
      api_key: ${{ secrets.SANDFLARE_API_KEY }}
      run: python debug_script.py
      keep_sandbox: 'true'
```

## Inputs

| Input                | Required | Default              | Description                                              |
|----------------------|----------|----------------------|----------------------------------------------------------|
| `api_key`            | ✅        | —                    | Sandflare API key — use `secrets.SANDFLARE_API_KEY`      |
| `run`                | ✅        | —                    | Command or script to execute inside the sandbox          |
| `template`           | ❌        | `""` (base Ubuntu)   | Sandbox template ID                                      |
| `size`               | ❌        | `small`              | VM size: `nano`, `small`, `medium`, `large`, `xl`        |
| `timeout`            | ❌        | `300`                | Execution timeout in seconds                             |
| `working_directory`  | ❌        | `/home/user`         | Working directory inside the sandbox                     |
| `upload_path`        | ❌        | `""`                 | Local file or directory to upload before running         |
| `upload_remote_path` | ❌        | `/home/user/workspace` | Remote path to place uploaded files                    |
| `keep_sandbox`       | ❌        | `false`              | If `true`, sandbox is not deleted after the run          |

## Outputs

| Output       | Description                            |
|--------------|----------------------------------------|
| `sandbox_id` | ID of the sandbox that was created     |
| `exit_code`  | Exit code of the executed command      |

## Why Sandflare?

- **Security** — every run gets a dedicated Firecracker microVM; no shared kernel with other tenants or your host runner
- **Reproducibility** — fresh environment every time, no leftover state between runs
- **Speed** — 50ms cold start from snapshot; faster than Docker containers for many workloads
- **Isolation** — perfect for running untrusted agent-generated code, eval harnesses, or user-submitted scripts

## Setup

1. [Sign up at sandflare.io](https://sandflare.io) and get an API key
2. Add it as a repository secret: **Settings → Secrets → `SANDFLARE_API_KEY`**
3. Add the action to your workflow

> **Note:** `entrypoint.sh` must be executable (`chmod +x entrypoint.sh`). It is already marked executable in this repository.

## Links

- [https://sandflare.io](https://sandflare.io)
- [https://docs.sandflare.io](https://docs.sandflare.io)
