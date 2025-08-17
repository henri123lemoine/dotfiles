#!/usr/bin/env python3
"""
Claude Code hook script that captures session end events and maps them to TMUX sessions.
This script is called by Claude when conversations end (Stop or Notification hooks).
"""

import fcntl
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

CACHE_FILE = os.path.expanduser("~/.claude/session_cache.json")
DEBUG_LOG = os.path.expanduser("~/.claude/hook_debug.log")


def debug_log(message):
    """Log debug information for troubleshooting."""
    try:
        with open(DEBUG_LOG, "a") as f:
            f.write(f"{datetime.now().isoformat()}: {message}\n")
    except Exception:
        pass  # Silently fail to avoid breaking the hook


def load_cache():
    """Load the session cache with file locking."""
    try:
        if not os.path.exists(CACHE_FILE):
            return {"last_update": datetime.now().isoformat(), "sessions": []}

        with open(CACHE_FILE, "r") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_SH)  # Shared lock for reading
            cache = json.load(f)
            return cache
    except Exception as e:
        debug_log(f"Error loading cache: {e}")
        return {"last_update": datetime.now().isoformat(), "sessions": []}


def save_cache(cache):
    """Save the session cache with file locking."""
    try:
        # Ensure directory exists
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)

        with open(CACHE_FILE, "w") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)  # Exclusive lock for writing
            json.dump(cache, f, indent=2)
    except Exception as e:
        debug_log(f"Error saving cache: {e}")


def get_current_tmux_pane_info():
    """Get current TMUX session, window, and pane info."""
    try:
        result = subprocess.run(
            [
                "tmux",
                "display-message",
                "-p",
                "#{session_name}:#{window_index}.#{pane_index}:#{pane_current_path}",
            ],
            capture_output=True,
            text=True,
            check=True,
            timeout=5,
        )

        output = result.stdout.strip()
        if ":" in output:
            parts = output.split(":")
            if len(parts) >= 3:
                session_window_pane = parts[0] + ":" + parts[1]  # "session:window.pane"
                current_path = ":".join(parts[2:])  # Handle paths with colons
                return session_window_pane, current_path
        return None, None
    except Exception as e:
        debug_log(f"Error getting current tmux pane info: {e}")
        return None, None


def get_tmux_sessions():
    """Get all TMUX sessions and their current working directories."""
    try:
        result = subprocess.run(
            [
                "tmux",
                "list-sessions",
                "-F",
                "#{session_name}:#{pane_current_path}:#{session_created}:#{session_activity}",
            ],
            capture_output=True,
            text=True,
            check=True,
            timeout=5,
        )

        sessions = {}
        for line in result.stdout.strip().split("\n"):
            if line:
                parts = line.split(":")
                if len(parts) >= 4:
                    session_name = parts[0]
                    current_path = parts[1]
                    created = parts[2]
                    activity = parts[3]

                    sessions[session_name] = {
                        "current_path": current_path,
                        "created": created,
                        "last_activity": activity,
                    }

        return sessions
    except Exception as e:
        debug_log(f"Error getting tmux sessions: {e}")
        return {}


def find_best_session_match(target_dir, sessions):
    """Find the best TMUX session match for a given directory."""
    target_path = Path(target_dir).resolve()

    best_match = None
    best_score = -1

    for session_name, info in sessions.items():
        try:
            session_path = Path(info["current_path"]).resolve()

            # Score based on path similarity
            score = 0

            # Exact match
            if target_path == session_path:
                score = 1000
            # Target is subdirectory of session
            elif target_path.is_relative_to(session_path):
                depth = len(target_path.relative_to(session_path).parts)
                score = 500 - depth * 10
            # Session is subdirectory of target
            elif session_path.is_relative_to(target_path):
                depth = len(session_path.relative_to(target_path).parts)
                score = 300 - depth * 10
            # Common prefix
            else:
                common_parts = 0
                for t_part, s_part in zip(target_path.parts, session_path.parts):
                    if t_part == s_part:
                        common_parts += 1
                    else:
                        break
                score = common_parts * 10

            if score > best_score:
                best_score = score
                best_match = session_name
        except Exception as e:
            debug_log(f"Error processing session {session_name}: {e}")
            continue

    return best_match, best_score


def cleanup_old_sessions(cache, max_age_hours=24):
    """Remove sessions older than max_age_hours from cache."""
    now = datetime.now()
    cleaned_sessions = []

    for session in cache.get("sessions", []):
        try:
            session_time = datetime.fromisoformat(session["timestamp"])
            age_hours = (now - session_time).total_seconds() / 3600

            if age_hours < max_age_hours:
                cleaned_sessions.append(session)
        except Exception:
            # Keep sessions with invalid timestamps for safety
            cleaned_sessions.append(session)

    cache["sessions"] = cleaned_sessions[-10:]  # Keep only last 10 sessions
    return cache


def main():
    try:
        # Read hook data from stdin with timeout
        start_time = time.time()
        hook_data = None

        # Simple timeout mechanism
        try:
            hook_data = json.load(sys.stdin)
        except Exception as e:
            debug_log(f"Error reading hook data: {e}")
            return

        # Extract relevant information
        session_id = hook_data.get("session_id")
        cwd = hook_data.get("cwd")
        hook_event = hook_data.get("hook_event_name")
        transcript_path = hook_data.get("transcript_path")

        debug_log(f"Hook fired: {hook_event}, session: {session_id}, cwd: {cwd}")

        # Only process Stop hooks for now
        if hook_event != "Stop":
            debug_log(f"Ignoring non-Stop hook: {hook_event}")
            return

        if not session_id or not cwd:
            debug_log("Missing required data (session_id or cwd)")
            return

        # Get current TMUX pane info (session:window.pane)
        current_pane, pane_cwd = get_current_tmux_pane_info()

        if current_pane and pane_cwd:
            debug_log(f"Current TMUX pane: {current_pane}, path: {pane_cwd}")

            # Use the current pane directly if the paths match
            pane_path = Path(pane_cwd).resolve()
            target_path = Path(cwd).resolve()

            if pane_path == target_path or target_path.is_relative_to(pane_path):
                debug_log(f"Direct pane match: {current_pane}")
                session_name = current_pane.split(":")[0]
                window_pane = (
                    current_pane.split(":", 1)[1] if ":" in current_pane else "0.0"
                )
            else:
                # Fallback to session matching
                tmux_sessions = get_tmux_sessions()
                if not tmux_sessions:
                    debug_log("No TMUX sessions found")
                    return

                session_name, score = find_best_session_match(cwd, tmux_sessions)
                if not session_name or score < 10:
                    debug_log(f"No good TMUX session match found")
                    return

                window_pane = "0.0"  # Default window/pane
                debug_log(f"Fallback session match: {session_name} (score: {score})")
        else:
            # Fallback to session matching only
            tmux_sessions = get_tmux_sessions()
            if not tmux_sessions:
                debug_log("No TMUX sessions found")
                return

            session_name, score = find_best_session_match(cwd, tmux_sessions)
            if not session_name or score < 10:
                debug_log(f"No good TMUX session match found")
                return

            current_pane = f"{session_name}:0.0"
            window_pane = "0.0"
            debug_log(f"Session-only match: {session_name} (score: {score})")

        # Update cache
        cache = load_cache()
        cache = cleanup_old_sessions(cache)

        # Add new session entry with precise pane info
        session_entry = {
            "timestamp": datetime.now().isoformat(),
            "claude_session_id": session_id,
            "tmux_session_name": session_name,
            "tmux_target": current_pane,  # Full session:window.pane
            "window_pane": window_pane,  # Just window.pane part
            "working_directory": cwd,
            "correlation_score": getattr(locals(), "score", 1000),
            "transcript_path": transcript_path,
        }

        cache["sessions"].append(session_entry)
        cache["last_update"] = datetime.now().isoformat()

        save_cache(cache)
        debug_log(f"Cache updated successfully")

    except Exception as e:
        debug_log(f"Unexpected error in hook: {e}")


if __name__ == "__main__":
    main()
