---
name: post-to-script
description: Turns one of Dylan's how-to blog posts in src/content/blog/*.mdx into a single runnable bash script at public/assets/<slug>/setup.sh, plus a download link in the post. Use whenever Dylan asks to "turn this post into a script", "extract the steps/commands from", "automate", "make a setup.sh for", or "script" one of his posts — or says something like "it'd be cool if readers could just run this" or "sum up all the commands in one script". Also use when he wants the GUI clicking in a post (Proxmox wizards, web UIs) replaced with the equivalent CLI calls. Do NOT use for writing or formatting post prose (that's format-blog-post), or for writing standalone scripts unrelated to a post.
---

# Post to Script

A how-to post is a runbook a human executes by reading top to bottom. This skill compiles that runbook into one bash
script a reader can download and run, and links it from the post.

Two artifacts come out of it:

1. `public/assets/<post-slug>/setup.sh` — executable, self-contained, safe to re-run
2. a short `<Callout>` in the post's `.mdx` linking to it

The hard part is not collecting the code blocks. It's that a post is written for someone with a screen in front of
them: context lives in prose, values are the author's own, some actions are clicks, and some things are only safe
because a human was watching. Steps 1–3 exist to recover all of that before you write a line of bash.

## Step 1: Read the whole post before writing anything

Read it end to end first. Converting block-by-block as you scroll produces scripts that run the right commands on the
wrong machine, because a code block's context almost never lives in the block — it lives in the paragraph or callout
above it.

In `building-a-home-server-pt4.mdx` (the post this skill was built against, and the best example to look at) that
shows up as:

- a callout saying "Run all of the following from within your LXC" that silently governs the next six code blocks
- a `chgrp`/`chmod` pair sitting inside that same LXC section whose prose says "Run this one **on the Proxmox host**"
- `192.168.1.88`, `dylan`, `1000`, `1005`, `Australia/Brisbane`, `100` — all Dylan's values, all things a reader
  must change
- `GENERATE-A-PASSWORD-TO-LOGIN` and `PUT-SONARR-API-KEY-HERE` — placeholders that must never become real defaults

Miss the second one and the script fails with a permissions error on someone else's machine at 2am, and they have no
idea why. That's the failure mode this whole skill is trying to avoid.

## Step 2: Build a step inventory

Write a table to your scratchpad before writing bash. It's cheap and it's the thing that catches dropped steps:

| # | Post heading | Runs on | Action | Scriptable |
|---|--------------|---------|--------|------------|
| 1 | Download a template | Proxmox host | `pveam update` + download Debian template | yes |
| 2 | Deploy LXC | Proxmox host (GUI) | Create CT wizard | yes, via `pct create` |
| 3 | Give your LXC a static IP | Proxmox host (GUI) | set static IPv4 + gateway | yes, via `pct set --net0` |
| 4 | Create a non-root user | inside LXC | `adduser`, `usermod -aG sudo` | yes, non-interactively |
| 5 | Point the apps at the right paths | app web UIs | set root folders, API keys | no — manual checklist |

Two columns do the real work. **Runs on** becomes the transport in the script. **Scriptable** forces you to decide
now, rather than quietly inventing a command later.

Reconcile the table against the post one more time at the end (Step 8) — it's your checklist for "did I drop
anything".

## Step 3: Resolve GUI steps into real commands

A reader who downloads a script has opted out of clicking, so a GUI step should become the actual CLI call, not an
`echo "now go click this"`. The wizard screenshots tell you what the settings *are*; your job is to find the flags
that set them.

Do not guess flag names. A plausible-looking wrong flag is worse than an honest manual step, because it fails on
someone else's machine where you can't see the error. Confirm anything you aren't certain of:

- prefer the `find-docs` skill for the tool's real documentation
- `<tool> --help` / `man <tool>` if you have the tool available
- web search as a fallback

If a step genuinely has no CLI path — clicking through an app's first-run web setup, pasting an API key that doesn't
exist until the app has started — don't fake it and don't silently drop it. Add it to the script's manual-steps
checklist (Step 5), which prints at the end. Being told "three things are left, here they are" is a good outcome. Being
told nothing and left with a half-configured stack is not.

## Step 4: Write the script

Copy `assets/script-template.sh` from this skill directory as the starting skeleton — it already has the header,
config block, preflight, logging helpers and manual-steps machinery wired up, so you only add the step functions.

The shape it enforces:

- **Header comment** — what this builds, which machine to run it on, and a line telling the reader to read it before
  running it. Someone is about to run this as root on hardware they care about; earning that trust costs four lines.
- **`set -euo pipefail`** — a runbook that continues after a failed step is worse than one that stops.
- **Config block** — every value the reader must change, at the top, one per line with a comment, written
  `VAR="${VAR:-default}"` so it can be overridden by environment without editing the file.
- **Preflight** — refuse to run in the wrong place. Cheap to write, saves a mangled machine.
- **One function per post section**, named after the heading (`download_template`, `create_container`,
  `install_docker`). A reader who is following along in the post should be able to find the matching function by name,
  and comment one out to skip it.
- **`main()` at the bottom** listing the calls in post order — the whole runbook readable in ten lines.

### Execution contexts

Pick the machine where the post's *first* command runs as the script's home, then reach outward from there using
whatever transport the post itself implies. Wrap each transport in a one-line helper so the step functions stay
readable:

```bash
in_ct() { pct exec "$CTID" -- bash -lc "$*"; }          # Proxmox host -> LXC
as_user() { pct exec "$CTID" -- su - "$USERNAME" -c "$*"; }  # ...as the non-root user
on_remote() { ssh -o BatchMode=yes "$REMOTE" "$*"; }    # laptop -> server
```

For pt4 that means the script runs **on the Proxmox host** and uses `pct exec` for everything inside the container.
Reaching for `ssh` there would be a mistake — a freshly created LXC has no sshd, no keys and no static IP yet, so the
first three steps would have nothing to connect to.

Note `bash -lc` and the quoting: heredocs and `$(...)` inside a `pct exec` string get evaluated in the wrong shell if
you're careless. When a step writes a file, prefer piping a quoted heredoc into the container over building a giant
one-liner:

```bash
pct exec "$CTID" -- bash -c 'cat > /home/'"$USERNAME"'/compose.yaml' <<'YAML'
services:
  ...
YAML
```

The quoted `<<'YAML'` matters: it stops the host shell expanding `$PUID` and friends before the file is written.

### Idempotency

The reader will run this twice — once when it fails halfway, once after fixing their config. Every step should be safe
the second time:

| Pattern | Instead of | Do |
|---|---|---|
| appending to a config file | `echo x >> f` | `grep -qxF 'x' f \|\| echo 'x' >> f` |
| creating a container | `pct create` | `pct status "$CTID" &>/dev/null \|\| pct create ...` |
| creating a user/group | `adduser` | `id -u "$U" &>/dev/null \|\| adduser ...` |
| downloading a template | `pveam download` | skip if `pveam list local` already lists it |
| starting things | `docker compose up -d` | already idempotent — leave it |

When a step edits a config file the post says to edit by hand (`nano /etc/pve/lxc/100.conf`), you need a way to find
your own previous edit and replace it rather than append a second copy.

The obvious move is to wrap your block in `# >>> managed by setup.sh` marker comments and delete between them on the
next run. That works in a file nobody else writes — but check who owns the file first, because a config another tool
manages will not necessarily leave your comments where you put them. Proxmox is the cautionary case: it treats `#`
lines in `/etc/pve/lxc/N.conf` as the container's *description* field, so on the next write it hoists them to the top
of the file and URL-encodes any non-ASCII in them. The markers end up detached from the `lxc.idmap:` lines they were
supposed to bracket, the delete-between-markers pass removes only the two comments, and the second run appends a
duplicate set of mappings — which makes the container refuse to start with `invalid map entry ... uid 0 is also
mapped`.

Match on the directive you own instead (`grep -v '^lxc\.idmap:'`), which is unambiguous and survives the file being
rewritten by its owner. Reach for marker comments only for files that are genuinely yours.

### Secrets and placeholders

Never bake a working credential into a file readers download. Where the post has a placeholder, the script should
either generate a value (`openssl rand -base64 24`) and print it once, or require it up front and fail fast:

```bash
: "${TRANSMISSION_PASS:?set TRANSMISSION_PASS before running}"
```

For a secret that can't exist yet — an API key the app only mints after first start — leave the placeholder in the
generated file and add a manual step telling the reader where to get it and what to re-run.

## Step 5: Report what wasn't automated

Collect the un-scriptable steps as you go and print them at the end:

```bash
MANUAL_STEPS=()
note_manual() { MANUAL_STEPS+=("$1"); }
...
note_manual "Sonarr > Media Management > Root Folder = /data/tv"
```

Print them under a clear heading when `main()` finishes, along with anything the script generated that the reader
needs to keep (passwords, URLs, IPs). This is the script's honest accounting of where it stopped.

## Step 6: Verify before you hand it over

- `bash -n <script>` — syntax check, always.
- `shellcheck <script>` if it's installed; skip it silently if not (it isn't, on this machine).
- `chmod +x` the file.
- Re-read the script against your Step 2 inventory. Every "yes" row should map to a visible line; every "no" row
  should map to a `note_manual`. Say out loud which rows are which — that's how dropped steps surface.

### Run it twice if you possibly can

Static review does not catch idempotency bugs. They only appear on the second run, and they are the most likely thing
to be wrong, because the first run is the one you were picturing while writing.

Dylan keeps a nested Proxmox VM for exactly this at `~/Downloads/proxmox-qemu-test/` — a full Proxmox install with a
ZFS pool, driven headlessly (see its `README.md`; SSH is forwarded to port 2222, and `qmp.py` does screenshots and
synthetic keystrokes). If the post targets Proxmox, offer to run the script there against a spare CTID before calling
it done. Run it, then run it again unchanged, and confirm the second run is a no-op that still ends in a working
state. Ask before booting or stopping that VM — he uses it for other things and may already have it running.

If you genuinely can't execute it, don't imply you did. Say what you actually verified: syntax parses, steps map to
the post, flags checked against docs, untested against real hardware.

## Step 7: Link it from the post

Add a `<Callout kind="tip">` near the top of the post, after the intro paragraph and before the first `##` section,
so a reader who wants the fast path sees it before scrolling through the manual one.

```mdx
<Callout kind="tip" title="Want to skip the typing?">
Everything below is also a script: [setup.sh](/assets/building-a-home-server-pt4/setup.sh). Read it first, set the
values at the top to match your network, then run it on the Proxmox host as root. The rest of this post explains what
it's doing and why.
</Callout>
```

Rules that apply to the `.mdx` edit:

- **Don't touch Dylan's existing words.** The callout is new content; everything around it stays byte-for-byte. Same
  golden rule as the `format-blog-post` skill.
- No emoji, anywhere — this repo's posts don't use them.
- `Callout` only renders in `.mdx`. If the post is `.md`, `git mv` it to `.mdx` and add the import line after the
  frontmatter, exactly as `format-blog-post` describes.
- Check the import is already there (`import Callout from '../../components/Callout.astro';`) before assuming it.
- Paths under `public/` are served from `/`, so `public/assets/x/setup.sh` links as `/assets/x/setup.sh`.

Don't suggest `curl ... | bash` anywhere. The whole point of the download link is that the reader gets to look at it
first.

## Step 8: Report back

In your reply, give Dylan:

- the script path and roughly how many steps it covers
- the config values a reader has to change (the block at the top)
- **the manual steps you couldn't automate, and why** — this is the part he most needs to sanity-check, because it's
  where you made a judgement call about what a script shouldn't do
- anything in the post that was ambiguous about which machine a command runs on
