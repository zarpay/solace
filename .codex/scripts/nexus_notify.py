#!/usr/bin/env python3
from __future__ import annotations

import getpass
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen

DEFAULT_NEXUS_URL = "https://nexus.zarhq.dev"
DEFAULT_TIMEOUT_SEC = 10
SKIPPED_USER_MESSAGES = ("<environment_context>",)


def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[1] == "--poll-device-token":
        return poll_device_token(argv[2], Path(argv[3]), argv[4])

    if len(argv) != 2:
        return 0

    notification = parse_json(argv[1])
    if not isinstance(notification, dict):
        return 0

    if notification.get("type") != "agent-turn-complete":
        return 0

    thread_id = notification.get("thread-id")
    if not isinstance(thread_id, str) or not thread_id:
        return 0

    state_db_path = resolve_state_db_path()
    if state_db_path is None:
        log("Could not locate Codex state database.")
        return 0

    rollout_path = lookup_rollout_path(state_db_path, thread_id)
    if rollout_path is None or not rollout_path.exists():
        log(f"Could not locate rollout for thread {thread_id}.")
        return 0

    transcript_data = load_transcript(rollout_path)
    if not transcript_data["content"]:
        return 0

    payload = build_payload(notification, rollout_path, transcript_data)
    if os.getenv("NEXUS_NOTIFY_DRY_RUN") == "1":
        print(
            json.dumps(
                {
                    "session_id": payload["session_id"],
                    "project": payload["project"],
                    "source": payload["source"],
                    "content_length": len(payload["content"]),
                    "content_preview": payload["content"][:500],
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0

    nexus_url = os.getenv("NEXUS_URL", DEFAULT_NEXUS_URL).rstrip("/")
    api_key = resolve_api_key(nexus_url)
    if not api_key:
        start_device_authorization(nexus_url)
        return 0

    ingest_transcript(nexus_url, api_key, payload)
    return 0


def parse_json(value: str) -> Any:
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        log("Failed to parse JSON payload.")
        return None


def resolve_codex_home() -> Path:
    return Path(os.getenv("CODEX_HOME", str(Path.home() / ".codex")))


def resolve_state_db_path() -> Path | None:
    override = os.getenv("CODEX_STATE_DB")
    if override:
        path = Path(override)
        return path if path.exists() else None

    codex_home = resolve_codex_home()
    candidates = sorted(codex_home.glob("state_*.sqlite"), key=lambda path: path.stat().st_mtime, reverse=True)
    if candidates:
        return candidates[0]

    fallback = codex_home / "state.sqlite"
    return fallback if fallback.exists() else None


def lookup_rollout_path(state_db_path: Path, thread_id: str) -> Path | None:
    try:
        connection = sqlite3.connect(f"file:{state_db_path}?mode=ro", uri=True)
    except sqlite3.Error as exc:
        log(f"Could not open state DB: {exc}")
        return None

    try:
        row = connection.execute(
            "SELECT rollout_path FROM threads WHERE id = ? LIMIT 1",
            (thread_id,),
        ).fetchone()
    except sqlite3.Error as exc:
        log(f"Could not query state DB: {exc}")
        return None
    finally:
        connection.close()

    if row is None or not row[0]:
        return None

    return Path(row[0])


def load_transcript(rollout_path: Path) -> dict[str, Any]:
    if rollout_path.suffix == ".json":
        return load_legacy_rollout(rollout_path)
    return load_jsonl_rollout(rollout_path)


def load_jsonl_rollout(rollout_path: Path) -> dict[str, Any]:
    messages: list[str] = []
    meta: dict[str, Any] = {}

    try:
        with rollout_path.open(encoding="utf-8") as handle:
            for line in handle:
                data = parse_json(line)
                if not isinstance(data, dict):
                    continue

                payload = data.get("payload")
                item_type = data.get("type")

                if item_type == "session_meta" and isinstance(payload, dict):
                    meta.setdefault("cwd", payload.get("cwd"))
                    meta.setdefault("cli_version", payload.get("cli_version"))
                    meta.setdefault("originator", payload.get("originator"))
                    meta.setdefault("model_provider", payload.get("model_provider"))
                elif item_type == "turn_context" and isinstance(payload, dict):
                    meta["cwd"] = payload.get("cwd", meta.get("cwd"))
                    meta["model"] = payload.get("model", meta.get("model"))
                elif item_type == "response_item" and isinstance(payload, dict):
                    message = extract_message_from_payload(payload)
                    if message:
                        messages.append(message)
    except OSError as exc:
        log(f"Could not read rollout: {exc}")

    return {"content": "\n\n---\n\n".join(messages), "meta": compact_dict(meta)}


def load_legacy_rollout(rollout_path: Path) -> dict[str, Any]:
    messages: list[str] = []
    meta: dict[str, Any] = {}

    try:
        data = json.loads(rollout_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        log(f"Could not read legacy rollout: {exc}")
        return {"content": "", "meta": {}}

    session = data.get("session", {})
    if isinstance(session, dict):
        meta["session_id"] = session.get("id")
        meta["timestamp"] = session.get("timestamp")

    for item in data.get("items", []):
        if not isinstance(item, dict):
            continue
        role = item.get("role")
        if role not in {"user", "assistant"}:
            continue
        text = extract_text(item.get("content"))
        if should_skip_message(role, text):
            continue
        if text:
            messages.append(f"{role}: {text}")

    return {"content": "\n\n---\n\n".join(messages), "meta": compact_dict(meta)}


def extract_message_from_payload(payload: dict[str, Any]) -> str | None:
    if payload.get("type") != "message":
        return None

    role = payload.get("role")
    if role not in {"user", "assistant"}:
        return None

    text = extract_text(payload.get("content"))
    if should_skip_message(role, text):
        return None

    if not text:
        return None

    return f"{role}: {text}"


def extract_text(content: Any) -> str:
    if isinstance(content, str):
        return content.strip()

    if not isinstance(content, list):
        return ""

    texts: list[str] = []
    for block in content:
        if not isinstance(block, dict):
            continue
        text = block.get("text")
        if isinstance(text, str) and text.strip():
            texts.append(text.strip())

    return "\n".join(texts).strip()


def should_skip_message(role: str, text: str) -> bool:
    if not text:
        return True
    if role == "user":
        stripped = text.strip()
        return any(stripped.startswith(prefix) for prefix in SKIPPED_USER_MESSAGES)
    return False


def build_payload(notification: dict[str, Any], rollout_path: Path, transcript_data: dict[str, Any]) -> dict[str, Any]:
    meta = dict(transcript_data.get("meta", {}))
    cwd = first_non_empty(notification.get("cwd"), meta.get("cwd"), os.getcwd())
    project = Path(cwd).name if cwd else None

    return compact_dict(
        {
            "content": transcript_data["content"],
            "source": "codex_cli",
            "session_id": notification.get("thread-id"),
            "project": project,
            "user": getpass.getuser(),
            "timestamp": utc_now_iso(),
            "participants": ["codex", "user"],
            "title": derive_title(notification, transcript_data["content"]),
            "tags": ["codex", project] if project else ["codex"],
            "context": compact_dict(
                {
                    "cwd": cwd,
                    "repo_root": find_git_root(cwd),
                    "rollout_path": str(rollout_path),
                    "turn_id": notification.get("turn-id"),
                    "cli_version": meta.get("cli_version"),
                    "originator": meta.get("originator"),
                    "model": first_non_empty(meta.get("model"), notification.get("model")),
                    "model_provider": meta.get("model_provider"),
                }
            ),
        }
    )


def derive_title(notification: dict[str, Any], content: str) -> str | None:
    for message in notification.get("input-messages", []):
        if isinstance(message, str) and message.strip():
            return message.strip()[:120]

    first_line = content.splitlines()[0].strip() if content else ""
    return first_line[:120] if first_line else None


def find_git_root(cwd: str | None) -> str | None:
    if not cwd:
        return None

    path = Path(cwd).resolve()
    for candidate in [path, *path.parents]:
        if (candidate / ".git").exists():
            return str(candidate)
    return None


def resolve_api_key(nexus_url: str) -> str | None:
    key_file = api_key_file(nexus_url)
    if key_file.exists():
        token = key_file.read_text(encoding="utf-8").strip()
        if token:
            return token

    token = os.getenv("NEXUS_API_KEY", "").strip()
    return token or None


def start_device_authorization(nexus_url: str) -> None:
    auth_response = post_json(f"{nexus_url}/device/authorize", payload=None, headers={})
    if not isinstance(auth_response, dict):
        return

    device_code = auth_response.get("device_code")
    user_code = auth_response.get("user_code")
    if not isinstance(device_code, str) or not isinstance(user_code, str):
        return

    device_url = f"{nexus_url}/device?device_code={device_code}"
    open_browser(device_url)
    log(f"Nexus authorization required. Visit {device_url} and enter code {user_code}.")

    try:
        subprocess.Popen(
            [
                sys.executable,
                str(Path(__file__).resolve()),
                "--poll-device-token",
                device_code,
                str(api_key_file(nexus_url)),
                nexus_url,
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as exc:
        log(f"Could not start Nexus auth poller: {exc}")


def poll_device_token(device_code: str, key_file: Path, nexus_url: str) -> int:
    key_file.parent.mkdir(parents=True, exist_ok=True)

    for _ in range(24):
        time.sleep(5)
        response = post_json(
            f"{nexus_url}/device/token",
            payload={"device_code": device_code},
            headers={},
        )
        if not isinstance(response, dict):
            continue

        token = response.get("access_token")
        if isinstance(token, str) and token:
            key_file.write_text(token, encoding="utf-8")
            os.chmod(key_file, 0o600)
            notify_authorized()
            return 0

        if response.get("error") == "expired_token":
            return 0

    return 0


def api_key_file(nexus_url: str) -> Path:
    host = urlparse(nexus_url).hostname or "nexus"
    config_home = Path(os.getenv("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    return config_home / "nexus" / f"api_key.{host}"


def ingest_transcript(nexus_url: str, api_key: str, payload: dict[str, Any]) -> None:
    response = post_json(
        f"{nexus_url}/transcripts/ingest",
        payload=payload,
        headers={"Authorization": f"Bearer {api_key}"},
    )
    if not isinstance(response, dict):
        log("Nexus transcript ingest did not return JSON.")


def post_json(url: str, payload: dict[str, Any] | None, headers: dict[str, str]) -> Any:
    if shutil.which("curl"):
        return post_json_with_curl(url, payload, headers)
    return post_json_with_urllib(url, payload, headers)


def post_json_with_curl(url: str, payload: dict[str, Any] | None, headers: dict[str, str]) -> Any:
    body = "" if payload is None else json.dumps(payload)
    command = [
        "curl",
        "--silent",
        "--show-error",
        "--max-time",
        str(DEFAULT_TIMEOUT_SEC),
        "--write-out",
        "\n__CURL_STATUS__:%{http_code}",
        "-X",
        "POST",
        url,
        "-H",
        "Accept: application/json",
        "-H",
        "Content-Type: application/json",
        "--data-raw",
        body,
    ]
    for key, value in headers.items():
        command.extend(["-H", f"{key}: {value}"])

    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        log(f"curl request failed for {url}: {exc}")
        return None

    if result.returncode != 0:
        log(f"curl request failed for {url}: {result.stderr.strip() or result.returncode}")
        return None

    status_code = None
    raw = result.stdout
    marker = "\n__CURL_STATUS__:"
    if marker in raw:
        raw, status_text = raw.rsplit(marker, 1)
        status_text = status_text.strip()
        status_code = int(status_text) if status_text.isdigit() else None

    raw = raw.strip()
    if status_code is not None and not 200 <= status_code < 300:
        log(f"curl request returned HTTP {status_code} for {url}: {raw[:200]}")
        return None

    if not raw:
        return {}

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        log(f"Non-JSON response from {url}: {raw[:200]}")
        return None


def post_json_with_urllib(url: str, payload: dict[str, Any] | None, headers: dict[str, str]) -> Any:
    body = b"" if payload is None else json.dumps(payload).encode("utf-8")
    request_headers = {"Content-Type": "application/json", **headers}
    request = Request(url, data=body, headers=request_headers, method="POST")

    try:
        with urlopen(request, timeout=DEFAULT_TIMEOUT_SEC) as response:
            raw = response.read()
    except (HTTPError, URLError, TimeoutError) as exc:
        log(f"HTTP request failed for {url}: {exc}")
        return None

    if not raw:
        return {}

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def open_browser(url: str) -> None:
    for command in (["open", url], ["xdg-open", url]):
        try:
            subprocess.Popen(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL,
                start_new_session=True,
            )
            return
        except OSError:
            continue


def notify_authorized() -> None:
    commands = [
        ["osascript", "-e", 'display notification "Device authorized successfully" with title "Nexus"'],
        ["notify-send", "Nexus", "Device authorized successfully"],
    ]
    for command in commands:
        try:
            subprocess.Popen(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL,
                start_new_session=True,
            )
            return
        except OSError:
            continue


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def compact_dict(value: dict[str, Any]) -> dict[str, Any]:
    return {key: item for key, item in value.items() if item not in (None, "", [], {})}


def first_non_empty(*values: Any) -> Any:
    for value in values:
        if value not in (None, ""):
            return value
    return None


def log(message: str) -> None:
    log_path = os.getenv("NEXUS_NOTIFY_LOG")
    if log_path:
        try:
            path = Path(log_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("a", encoding="utf-8") as handle:
                handle.write(f"{utc_now_iso()} {message}\n")
        except OSError:
            pass


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
