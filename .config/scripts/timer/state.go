package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

type Timer struct {
	ID      string `json:"id"`
	Label   string `json:"label"`
	Seconds int    `json:"seconds"`
	FireAt  int64  `json:"fire_at"`
	Session string `json:"session"`
	PID     int    `json:"pid"`
}

func stateDir() string {
	return filepath.Join(os.Getenv("HOME"), ".local", "state", "tmux-timers")
}

func timerPath(id string) string {
	return filepath.Join(stateDir(), id+".json")
}

func ensureStateDir() error {
	return os.MkdirAll(stateDir(), 0755)
}

func loadTimer(id string) (*Timer, error) {
	data, err := os.ReadFile(timerPath(id))
	if err != nil {
		return nil, err
	}
	var t Timer
	if err := json.Unmarshal(data, &t); err != nil {
		return nil, err
	}
	return &t, nil
}

func saveTimer(t *Timer) error {
	if err := ensureStateDir(); err != nil {
		return err
	}
	data, err := json.Marshal(t)
	if err != nil {
		return err
	}
	return os.WriteFile(timerPath(t.ID), data, 0644)
}

func removeTimer(id string) {
	os.Remove(timerPath(id))
}

func loadAllTimers() []*Timer {
	dir := stateDir()
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	now := time.Now().Unix()
	var timers []*Timer
	for _, e := range entries {
		if filepath.Ext(e.Name()) != ".json" {
			continue
		}
		id := e.Name()[:len(e.Name())-5]
		t, err := loadTimer(id)
		if err != nil {
			continue
		}
		if t.FireAt <= now {
			removeTimer(id)
			continue
		}
		timers = append(timers, t)
	}
	return timers
}

func cancelTimer(t *Timer) {
	if t.PID > 0 {
		syscall.Kill(t.PID, syscall.SIGTERM)
	}
	removeTimer(t.ID)
}

func createTimer(seconds int) error {
	if err := ensureStateDir(); err != nil {
		return err
	}

	label := formatLabel(seconds)
	out, err := exec.Command("tmux", "display-message", "-p", "#{session_name}").Output()
	if err != nil {
		return fmt.Errorf("not in tmux")
	}
	session := strings.TrimSpace(string(out))

	id := fmt.Sprintf("%x", time.Now().UnixNano())

	exePath, err := os.Executable()
	if err != nil {
		return err
	}

	t := &Timer{
		ID:      id,
		Label:   label,
		Seconds: seconds,
		FireAt:  time.Now().Unix() + int64(seconds),
		Session: session,
	}

	cmd := exec.Command(exePath, "fire", id, "--delay", strconv.Itoa(seconds))
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	cmd.Stdout = nil
	cmd.Stderr = nil
	cmd.Stdin = nil
	if err := cmd.Start(); err != nil {
		return err
	}

	t.PID = cmd.Process.Pid
	if err := saveTimer(t); err != nil {
		cmd.Process.Kill()
		return err
	}

	cmd.Process.Release()
	return nil
}
