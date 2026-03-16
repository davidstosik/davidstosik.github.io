---
title: Storing OpenClaw secrets in 1Password
category: dev
tags: [openclaw, 1password, security]
---

I've been running [OpenClaw](https://openclaw.ai) as my personal AI assistant for a few weeks now — it's an open-source gateway that connects LLMs to messaging channels, tools, and your local environment. Really cool project.

One thing that bugged me quickly: API keys. OpenClaw needs keys for LLM providers, TTS services, search APIs — and they add up fast. It supports a [SecretRef system](https://docs.openclaw.ai/gateway/secrets) to avoid storing secrets as plaintext in `openclaw.json`, but the built-in `exec` provider pattern requires a separate provider block per secret, each with the 1Password item path hardcoded in the command arguments. Not great if you have several keys to manage.

## Before

```json
"secrets": {
  "providers": {
    "op_elevenlabs": {
      "source": "exec",
      "command": "/usr/local/bin/op",
      "args": ["read", "op://MyVault/ElevenLabs/password"],
      "passEnv": ["HOME"],
      "jsonOnly": false
    },
    "op_openai": {
      "source": "exec",
      "command": "/usr/local/bin/op",
      "args": ["read", "op://MyVault/OpenAI/password"],
      "passEnv": ["HOME"],
      "jsonOnly": false
    }
  }
}
```

One provider per secret, item path buried in args. With `jsonOnly: false`, each provider outputs a raw value — meaning one provider can only serve one secret. Add a third API key and you're copy-pasting yet another block.

## The exec protocol

OpenClaw's exec provider speaks a [simple JSON protocol](https://docs.openclaw.ai/gateway/secrets#exec-provider) over stdin/stdout. When `jsonOnly: true`, instead of expecting a raw value, OpenClaw sends a JSON request to the script's stdin:

```json
{
  "protocolVersion": 1,
  "provider": "onepassword",
  "ids": ["op://MyVault/ElevenLabs/password", "op://MyVault/OpenAI/password"]
}
```

The script resolves whatever it can and returns:

```json
{
  "protocolVersion": 1,
  "values": {
    "op://MyVault/ElevenLabs/password": "sk-...",
    "op://MyVault/OpenAI/password": "sk-..."
  }
}
```

The key detail: OpenClaw batches all IDs for a provider into a single call. The script is invoked once per provider activation, not once per secret. So a shim that loops through IDs and calls `op read` for each one is all you need.

## The shim

A small Ruby script that bridges the protocol to 1Password CLI:

```ruby
ids.each do |id|
  out, err, status = Open3.capture3("op", "read", id)
  status.success? ? values[id] = out.strip : errors[id] = { message: err.strip }
end
```

A couple of things to watch for:

- **Shebang path:** OpenClaw runs exec providers in a restricted environment. The interpreter must be absolute, or resolvable via the `PATH` forwarded through `passEnv`.
- **`passEnv` allowlist:** Only the environment variables you explicitly list are forwarded to the script. If `op` can't find its config or token, this is probably why.

## After

```json
"secrets": {
  "providers": {
    "onepassword": {
      "source": "exec",
      "command": "/path/to/openclaw-1password-resolver.rb",
      "jsonOnly": true,
      "passEnv": ["PATH", "OP_SERVICE_ACCOUNT_TOKEN"]
    }
  }
},
"messages": {
  "tts": {
    "elevenlabs": {
      "apiKey": {
        "source": "exec",
        "provider": "onepassword",
        "id": "op://MyVault/ElevenLabs/password"
      }
    }
  }
}
```

One provider, any number of secrets. Each SecretRef just names the provider and passes an `op://` URI as the `id` — no indirection, no per-secret config blocks. Adding a new secret is one line.

## Packaged as a skill

OpenClaw has a "skills" system — SKILL.md files that tell the agent how to perform specific tasks. I packaged the shim and setup instructions as a skill so the agent knows where the script lives, understands the protocol, and can wire new secrets into the config without me explaining it every time. Want to add a new API key? The agent reads the skill, creates the 1Password item, and updates `openclaw.json` — no manual steps.

## The limitation

The `OP_SERVICE_ACCOUNT_TOKEN` still lives in `~/.openclaw/.env`. So I've moved the actual API keys out of plaintext, but the token that unlocks them isn't yet protected the same way. It's a real improvement — a single scoped token is much easier to rotate and audit than a dozen scattered API keys — but it's not the whole way there. Next step: bootstrap it from the macOS Keychain instead.
