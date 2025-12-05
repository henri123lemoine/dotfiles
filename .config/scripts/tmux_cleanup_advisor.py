#!/usr/bin/env python3
import subprocess
from collections import defaultdict


def parse_elapsed(elapsed_str):
    """Parse ps elapsed time to hours"""
    elapsed_str = elapsed_str.strip()
    if "-" in elapsed_str:
        days, time = elapsed_str.split("-", 1)
        days = int(days)
        parts = time.split(":")
        return days * 24 + int(parts[0]) + int(parts[1]) / 60.0
    parts = elapsed_str.split(":")
    if len(parts) == 3:
        return int(parts[0]) + int(parts[1]) / 60.0
    elif len(parts) == 2:
        return int(parts[0]) / 60.0
    return 0


def get_tmux_panes():
    """Get all tmux panes"""
    result = subprocess.run(
        [
            "tmux",
            "list-panes",
            "-a",
            "-F",
            "#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}|#{pane_current_path}|#{pane_active}",
        ],
        capture_output=True,
        text=True,
        timeout=5,
    )
    panes = {}
    for line in result.stdout.strip().split("\n"):
        if "|" not in line:
            continue
        parts = line.split("|")
        if len(parts) >= 4:
            try:
                panes[int(parts[1])] = {
                    "location": parts[0],
                    "path": parts[2],
                    "active": parts[3] == "1",
                }
            except ValueError:
                pass
    return panes


def get_process_cwd(pid):
    """Get working directory"""
    try:
        result = subprocess.run(
            ["lsof", "-p", str(pid), "-a", "-d", "cwd"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        for line in result.stdout.split("\n"):
            if "cwd" in line:
                return line.split()[-1]
    except:
        pass
    return None


def shorten_path(path, max_len=40):
    """Shorten path for display"""
    if not path or len(path) <= max_len:
        return path
    import os

    home = os.path.expanduser("~")
    if path.startswith(home):
        path = "~" + path[len(home) :]
    if len(path) <= max_len:
        return path
    parts = path.split("/")
    if len(parts) > 3:
        return ".../" + "/".join(parts[-2:])
    return path[: max_len - 3] + "..."


def main():
    print("🔍 Analyzing tmux processes...\n")

    tmux_panes = get_tmux_panes()
    print(f"Found {len(tmux_panes)} tmux panes")

    # Get all processes
    result = subprocess.run(
        ["ps", "-axo", "pid,ppid,rss,etime,command"], capture_output=True, text=True
    )

    processes = []
    pid_to_ppid = {}

    for line in result.stdout.strip().split("\n")[1:]:
        parts = line.split(None, 4)
        if len(parts) >= 5:
            try:
                pid, ppid, rss_kb = int(parts[0]), int(parts[1]), int(parts[2])
                hours = parse_elapsed(parts[3])
                cmd = parts[4]

                processes.append(
                    {
                        "pid": pid,
                        "ppid": ppid,
                        "rss_mb": rss_kb / 1024.0,
                        "hours": hours,
                        "command": cmd,
                    }
                )
                pid_to_ppid[pid] = ppid
            except ValueError:
                pass

    print(f"Found {len(processes)} total processes\n")

    # Find tmux descendants
    tmux_pids = [
        p["pid"] for p in processes if "tmux" in p["command"] and p["rss_mb"] > 10
    ]
    descendants = set()

    def walk(pid):
        if pid in descendants:
            return
        descendants.add(pid)
        for p in processes:
            if p["ppid"] == pid:
                walk(p["pid"])

    for tmux_pid in tmux_pids:
        walk(tmux_pid)

    # Find pane for each process by walking up parent tree
    def find_pane(pid):
        current, depth = pid, 0
        while current and current != 1 and depth < 15:
            if current in tmux_panes:
                return tmux_panes[current]["location"], tmux_panes[current]["active"]
            current = pid_to_ppid.get(current)
            depth += 1
        return None, False

    # Score candidates
    candidates = []
    import math

    for p in processes:
        if p["pid"] not in descendants or p["pid"] in tmux_pids:
            continue
        if p["rss_mb"] < 5 or p["hours"] < 0.08:
            continue

        pane_loc, is_active = find_pane(p["pid"])
        cwd = get_process_cwd(p["pid"])

        # Calculate score
        score = p["rss_mb"] * math.log(p["hours"] + 1)
        if "nvim --embed" in p["command"]:
            score *= 1.5
        elif "claude" in p["command"].lower():
            score *= 1.3
        elif "python" in p["command"] and p["rss_mb"] > 20:
            score *= 1.2
        elif "zsh" in p["command"] or "bash" in p["command"]:
            score *= 0.3
        if is_active:
            score *= 0.05

        display_loc = pane_loc if pane_loc else shorten_path(cwd) if cwd else "Unknown"

        candidates.append(
            {
                "pid": p["pid"],
                "rss_mb": p["rss_mb"],
                "hours": p["hours"],
                "score": score,
                "command": p["command"],
                "pane_location": pane_loc,
                "display_location": display_loc,
                "cwd": cwd,
                "active": is_active,
            }
        )

    candidates.sort(key=lambda x: x["score"], reverse=True)

    # Display
    print("=" * 130)
    print(
        f"{'SCORE':>8} | {'MEM':>7} | {'AGE':>10} | {'LOCATION/PATH':>40} | {'COMMAND'}"
    )
    print("=" * 130)

    total = 0
    for c in candidates[:30]:
        age_str = (
            f"{int(c['hours'] * 60)}min"
            if c["hours"] < 1
            else f"{c['hours']:.1f}h"
            if c["hours"] < 24
            else f"{c['hours'] / 24:.1f}d"
        )
        marker = "🟢" if c["active"] else ("📂" if not c["pane_location"] else "  ")
        total += c["rss_mb"]
        print(
            f"{c['score']:8.1f} | {c['rss_mb']:6.1f}M | {age_str:>10} | {c['display_location']:>40} | {marker} {c['command'][:50]}"
        )

    print("=" * 130)
    print(f"\nTop 30 candidates total: {total:.1f} MB ({len(candidates)} total found)")

    # Group unknowns by directory
    unknown_by_dir = defaultdict(list)
    for c in candidates:
        if not c["pane_location"] and c["cwd"]:
            parts = c["cwd"].split("/")
            project_dir = (
                "/".join(parts[:6])
                if len(parts) > 5 and c["cwd"].startswith("/Users/")
                else c["cwd"]
            )
            unknown_by_dir[project_dir].append(c)

    if unknown_by_dir:
        print("\n📂 Orphaned processes (no tmux pane):")
        for dir_path, procs in sorted(
            unknown_by_dir.items(),
            key=lambda x: sum(p["rss_mb"] for p in x[1]),
            reverse=True,
        )[:8]:
            total_mem = sum(p["rss_mb"] for p in procs)
            print(
                f"\n  {shorten_path(dir_path, 60)} ({len(procs)} procs, {total_mem:.1f} MB):"
            )
            for p in sorted(procs, key=lambda x: x["rss_mb"], reverse=True)[:3]:
                age = (
                    f"{p['hours']:.1f}h"
                    if p["hours"] < 24
                    else f"{p['hours'] / 24:.1f}d"
                )
                print(
                    f"    PID {p['pid']:6} - {p['rss_mb']:5.1f}MB - {age:>6} - {p['command'][:55]}"
                )

    print("\n💡 Tips:")
    print("  🟢 = active pane  |  📂 = orphaned (no pane, showing directory)")
    print("  Navigate: tmux switch-client -t <location>")
    print("  Kill: kill <pid>")


if __name__ == "__main__":
    main()
