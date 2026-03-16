---
title: Storing OpenClaw secrets in 1Password
category: dev
---

I've been running [OpenClaw](https://openclaw.ai) as my personal AI assistant for a few weeks now — it's an open-source gateway that connects LLMs to messaging channels, tools, and your local environment. Really cool project.

One thing that bugged me quickly: API keys. OpenClaw supports a [SecretRef system](https://docs.openclaw.ai/gateway/secrets) to avoid storing secrets as plaintext in `openclaw.json`, but the built-in `exec` provider pattern requires a separate provider block per secret, each with the 1Password item path hardcoded in the command arguments. Not great if you have several keys to manage.

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

One provider per secret, item path buried in args.

## The idea

OpenClaw's exec provider speaks a [simple JSON protocol](https://docs.openclaw.ai/gateway/secrets#exec-provider) over stdin/stdout. Instead of calling `op read` directly, I wrote a small Ruby shim that:

1. Receives a batch request from OpenClaw with a list of secret IDs
2. Calls `op read <id>` for each one
3. Returns all values in a single JSON response

The IDs are `op://` URIs — so the config stays self-documenting and there's no mapping table to maintain.

```ruby
ids.each do |id|
  out, err, status = Open3.capture3("op", "read", id)
  status.success? ? values[id] = out.strip : errors[id] = { message: err.strip }
end
```

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
      "apiKey": { "source": "exec", "provider": "onepassword", "id": "op://MyVault/ElevenLabs/password" }
    }
  }
}
```

One provider, any number of secrets. The `id` *is* the `op://` URI — no indirection.

## Packaged as a skill

OpenClaw has a "skills" system — SKILL.md files that tell the agent how to set things up. I packaged the shim and setup instructions as a skill so the agent knows where the script lives and can wire new secrets into the config without me explaining the protocol every time.

## The limitation

The `OP_SERVICE_ACCOUNT_TOKEN` still lives in `~/.openclaw/.env`. So I've moved the actual API keys out of plaintext, but the token that unlocks them isn't yet. Next step: bootstrap it from the macOS Keychain instead.
