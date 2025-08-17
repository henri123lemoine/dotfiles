#!/usr/bin/env python3
"""
Script to switch to the TMUX session containing the most recent Claude conversation.
This is triggered by a hotkey and reads from the session cache.
"""

import json
import os
import subprocess
import sys
from datetime import datetime

CACHE_FILE = os.path.expanduser("~/.claude/session_cache.json")
LOG_FILE = os.path.expanduser("~/.claude/switcher.log")


def log_message(message):
    """Log messages for debugging."""
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"{datetime.now().isoformat()}: {message}\n")
    except Exception:
        pass


def load_cache():
    """Load the session cache."""
    try:
        if not os.path.exists(CACHE_FILE):
            log_message("Cache file does not exist")
            return None

        with open(CACHE_FILE, "r") as f:
            cache = json.load(f)
            return cache
    except Exception as e:
        log_message(f"Error loading cache: {e}")
        return None


def get_current_tmux_session():
    """Get the currently active TMUX session name."""
    try:
        result = subprocess.run(
            ["tmux", "display-message", "-p", "#{session_name}"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except Exception:
        return None


def session_exists(session_name):
    """Check if a TMUX session exists."""
    try:
        subprocess.run(
            ["tmux", "has-session", "-t", session_name], capture_output=True, check=True
        )
        return True
    except subprocess.CalledProcessError:
        return False


def bring_wezterm_to_front():
    """Bring WezTerm app to front and focus it."""
    try:
        # Use AppleScript to activate WezTerm
        script = """
        tell application "WezTerm"
            activate
        end tell
        """
        subprocess.run(["osascript", "-e", script], check=True, capture_output=True)
        log_message("Brought WezTerm to front")
        return True
    except Exception as e:
        log_message(f"Error bringing WezTerm to front: {e}")
        return False


def switch_to_session(target):
    """Switch to a TMUX session/window/pane and bring WezTerm to front."""
    # First bring WezTerm to front
    if not bring_wezterm_to_front():
        return False, "Could not bring WezTerm to front"

    # Small delay to let WezTerm come to front
    import time

    time.sleep(0.3)

    # Parse target (could be "session" or "session:window.pane")
    if ":" in target and "." in target.split(":")[-1]:
        # Precise target: session:window.pane
        session_name = target.split(":")[0]
        precise_target = target
    else:
        # Just session name
        session_name = target
        precise_target = target

    current_session = get_current_tmux_session()

    if not session_exists(session_name):
        log_message(f"Session does not exist: {session_name}")
        return False, f"Session not found: {session_name}"

    try:
        # Use precise target if available
        if current_session:
            subprocess.run(
                ["tmux", "switch-client", "-t", precise_target],
                check=True,
                capture_output=True,
            )
            log_message(f"Switched to precise target: {precise_target}")
            return True, f"Switched to: {precise_target}"
        else:
            # If not currently in tmux, attach to session then switch to pane
            subprocess.run(
                ["tmux", "attach-session", "-t", session_name],
                check=True,
                capture_output=True,
            )
            log_message(f"Attached to session: {session_name}")

            # If we have a precise target, switch to it after attaching
            if precise_target != session_name:
                time.sleep(0.1)  # Brief delay
                subprocess.run(
                    ["tmux", "select-window", "-t", precise_target],
                    check=True,
                    capture_output=True,
                )
                log_message(f"Selected precise target: {precise_target}")

            return True, f"Connected to: {precise_target}"

    except subprocess.CalledProcessError as e:
        log_message(f"Error with direct tmux commands: {e}")
        # Try alternative approach with new-session
        try:
            subprocess.run(
                ["tmux", "new-session", "-d", "-t", session_name],
                check=True,
                capture_output=True,
            )
            log_message(f"Created new client for session: {session_name}")
            return True, f"Connected to: {session_name}"
        except subprocess.CalledProcessError as e2:
            log_message(f"All tmux methods failed: {e2}")
            return False, f"Could not switch to session"


def show_notification(message, success=True):
    """Show a system notification."""
    try:
        # Use osascript for macOS notifications
        if success:
            sound = "Glass"
            title = "Claude Session Switch"
        else:
            sound = "Sosumi"
            title = "Claude Session Switch - Error"

        script = f"""
        display notification "{message}" with title "{title}" sound name "{sound}"
        """
        subprocess.run(["osascript", "-e", script], capture_output=True)
    except Exception as e:
        log_message(f"Error showing notification: {e}")


def main():
    log_message("Session switcher started")

    # Load cache
    cache = load_cache()
    if not cache:
        message = "No session cache found"
        log_message(message)
        show_notification(message, success=False)
        return 1

    sessions = cache.get("sessions", [])
    if not sessions:
        message = "No sessions in cache"
        log_message(message)
        show_notification(message, success=False)
        return 1

    # Get the most recent session
    latest_session = max(sessions, key=lambda s: s.get("timestamp", ""))

    session_name = latest_session.get("tmux_session_name")
    tmux_target = latest_session.get("tmux_target")  # Full session:window.pane
    working_dir = latest_session.get("working_directory", "unknown")

    if not session_name:
        message = "No TMUX session in latest entry"
        log_message(message)
        show_notification(message, success=False)
        return 1

    # Use precise target if available, otherwise fall back to session name
    target = tmux_target if tmux_target else session_name
    log_message(f"Attempting to switch to: {target} (from {working_dir})")

    # Switch to the session/window/pane
    success, message = switch_to_session(target)

    # Show notification
    show_notification(message, success=success)

    if success:
        log_message(f"Successfully switched to {session_name}")
        return 0
    else:
        log_message(f"Failed to switch to {session_name}: {message}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
