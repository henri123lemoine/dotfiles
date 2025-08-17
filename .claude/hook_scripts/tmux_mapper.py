#!/usr/bin/env python3
"""
Script to map TMUX sessions to their working directories.
This helps correlate Claude sessions with TMUX sessions.
"""

import json
import subprocess
import sys
from pathlib import Path


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
    except subprocess.CalledProcessError as e:
        print(f"Error getting tmux sessions: {e}", file=sys.stderr)
        return {}
    except FileNotFoundError:
        print("tmux not found", file=sys.stderr)
        return {}


def find_best_session_match(target_dir, sessions):
    """Find the best TMUX session match for a given directory."""
    target_path = Path(target_dir).resolve()

    best_match = None
    best_score = -1

    for session_name, info in sessions.items():
        session_path = Path(info["current_path"]).resolve()

        # Score based on path similarity
        score = 0

        # Exact match
        if target_path == session_path:
            score = 1000
        # Target is subdirectory of session
        elif target_path.is_relative_to(session_path):
            # Closer subdirectories score higher
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

    return best_match, best_score


def main():
    if len(sys.argv) > 1:
        # Test mode: find best match for given directory
        target_dir = sys.argv[1]
        sessions = get_tmux_sessions()

        if not sessions:
            print("No TMUX sessions found")
            return

        match, score = find_best_session_match(target_dir, sessions)
        print(f"Best match for '{target_dir}': {match} (score: {score})")

        print("\nAll sessions:")
        for name, info in sessions.items():
            print(f"  {name}: {info['current_path']}")
    else:
        # Normal mode: output JSON mapping
        sessions = get_tmux_sessions()
        print(json.dumps(sessions, indent=2))


if __name__ == "__main__":
    main()
