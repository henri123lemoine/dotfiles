package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "fire":
			cmdFire()
		case "alarm":
			cmdAlarm()
		default:
			fmt.Fprintf(os.Stderr, "unknown command: %s\n", os.Args[1])
			os.Exit(1)
		}
		return
	}

	p := tea.NewProgram(newModel())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func cmdFire() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "usage: timer fire <id> --delay <seconds>")
		os.Exit(1)
	}
	id := os.Args[2]

	var delay int
	for i := 3; i < len(os.Args)-1; i++ {
		if os.Args[i] == "--delay" {
			if d, err := strconv.Atoi(os.Args[i+1]); err == nil {
				delay = d
			}
		}
	}

	if delay > 0 {
		time.Sleep(time.Duration(delay) * time.Second)
	}

	t, err := loadTimer(id)
	if err != nil {
		os.Exit(0)
	}

	go exec.Command("afplay", "/System/Library/Sounds/Hero.aiff").Run()

	exec.Command("osascript", "-e",
		fmt.Sprintf(`display notification "%s timer done" with title "Timer" sound name "Hero"`, t.Label),
	).Run()

	exePath, _ := os.Executable()
	exec.Command("tmux", "display-popup",
		"-t", t.Session,
		"-w", "35%", "-h", "7",
		"-E", fmt.Sprintf("%s alarm %s", exePath, id),
	).Run()

	removeTimer(id)
}

func cmdAlarm() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "usage: timer alarm <id>")
		os.Exit(1)
	}
	label := "timer"
	if t, err := loadTimer(os.Args[2]); err == nil {
		label = t.Label
	}

	p := tea.NewProgram(newAlarmModel(label), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		os.Exit(1)
	}
}
