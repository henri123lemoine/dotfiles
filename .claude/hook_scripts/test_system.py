#!/usr/bin/env python3
"""
Test script to verify the Claude + TMUX session switching system.
"""

import json
import os
import subprocess
import sys


def test_tmux_mapping():
    """Test TMUX session mapping."""
    print("🔍 Testing TMUX session mapping...")

    try:
        result = subprocess.run(
            [
                "python3",
                "/Users/henrilemoine/.claude/tmux_mapper.py",
                "/Users/henrilemoine/.claude",
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        print("✅ TMUX mapping works:")
        print(result.stdout)
        return True
    except Exception as e:
        print(f"❌ TMUX mapping failed: {e}")
        return False


def test_hook_simulation():
    """Simulate a Claude hook call."""
    print("\n🔍 Testing hook simulation...")

    # Create fake hook data
    hook_data = {
        "session_id": "test-session-123",
        "transcript_path": "/path/to/test.jsonl",
        "cwd": "/Users/henrilemoine/.claude",
        "hook_event_name": "Stop",
    }

    try:
        # Run the hook script with simulated data
        process = subprocess.Popen(
            ["python3", "/Users/henrilemoine/.claude/claude_tmux_hook.py"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        stdout, stderr = process.communicate(input=json.dumps(hook_data))

        if process.returncode == 0:
            print("✅ Hook simulation successful")

            # Check if cache was created
            cache_file = "/Users/henrilemoine/.claude/session_cache.json"
            if os.path.exists(cache_file):
                with open(cache_file, "r") as f:
                    cache = json.load(f)
                    sessions = cache.get("sessions", [])
                    if sessions:
                        latest = sessions[-1]
                        print(
                            f"   📝 Cache entry: {latest['tmux_session_name']} <- {latest['claude_session_id']}"
                        )
                        return True
                    else:
                        print("   ⚠️ Cache created but no sessions found")
                        return False
            else:
                print("   ⚠️ Cache file not created")
                return False
        else:
            print(f"❌ Hook simulation failed: {stderr}")
            return False

    except Exception as e:
        print(f"❌ Hook simulation error: {e}")
        return False


def test_session_switcher():
    """Test the session switcher."""
    print("\n🔍 Testing session switcher...")

    try:
        result = subprocess.run(
            [
                "python3",
                "/Users/henrilemoine/.claude/hook_scripts/switch_to_latest_claude_session.py",
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print("✅ Session switcher works")
            return True
        else:
            print(f"❌ Session switcher failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"❌ Session switcher error: {e}")
        return False


def test_files_exist():
    """Check that all required files exist and are executable."""
    print("🔍 Checking file existence and permissions...")

    files = [
        ("/Users/henrilemoine/.claude/hook_scripts/tmux_mapper.py", True),
        ("/Users/henrilemoine/.claude/hook_scripts/claude_tmux_hook.py", True),
        (
            "/Users/henrilemoine/.claude/hook_scripts/switch_to_latest_claude_session.py",
            True,
        ),
        ("/Users/henrilemoine/.claude/settings.json", False),
    ]

    all_good = True
    for file_path, should_be_executable in files:
        if os.path.exists(file_path):
            if should_be_executable and not os.access(file_path, os.X_OK):
                print(f"❌ {file_path} exists but is not executable")
                all_good = False
            else:
                print(f"✅ {file_path}")
        else:
            print(f"❌ {file_path} does not exist")
            all_good = False

    return all_good


def main():
    print("🧪 Claude Code + TMUX Session Switcher Test Suite")
    print("=" * 50)

    tests = [
        ("File existence", test_files_exist),
        ("TMUX mapping", test_tmux_mapping),
        ("Hook simulation", test_hook_simulation),
        ("Session switcher", test_session_switcher),
    ]

    results = []
    for test_name, test_func in tests:
        print(f"\n{'='*20} {test_name} {'='*20}")
        results.append(test_func())

    print(f"\n{'='*50}")
    print("📊 Test Results:")
    for i, (test_name, _) in enumerate(tests):
        status = "✅ PASS" if results[i] else "❌ FAIL"
        print(f"   {test_name}: {status}")

    if all(results):
        print("\n🎉 All tests passed! The system should be ready to use.")
        print("\nNext steps:")
        print("1. Add the Hammerspoon config to ~/.hammerspoon/init.lua")
        print("2. Reload Hammerspoon configuration")
        print("3. Test by ending a Claude conversation and pressing Cmd+Shift+C")
    else:
        print("\n⚠️ Some tests failed. Check the output above for details.")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
