package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

func parseDuration(input string) (int, error) {
	input = strings.TrimSpace(strings.ToLower(input))
	if input == "" {
		return 0, fmt.Errorf("empty input")
	}

	if n, err := strconv.Atoi(input); err == nil {
		if n <= 0 {
			return 0, fmt.Errorf("duration must be positive")
		}
		return n * 60, nil
	}

	re := regexp.MustCompile(`(\d+)(h|m|s)`)
	matches := re.FindAllStringSubmatch(input, -1)
	if len(matches) == 0 {
		return 0, fmt.Errorf("invalid format")
	}

	var consumed string
	for _, m := range matches {
		consumed += m[0]
	}
	if consumed != input {
		return 0, fmt.Errorf("invalid format")
	}

	var total int
	for _, m := range matches {
		n, _ := strconv.Atoi(m[1])
		switch m[2] {
		case "h":
			total += n * 3600
		case "m":
			total += n * 60
		case "s":
			total += n
		}
	}

	if total <= 0 {
		return 0, fmt.Errorf("duration must be positive")
	}
	return total, nil
}

func formatLabel(seconds int) string {
	if seconds >= 3600 {
		h := seconds / 3600
		m := (seconds % 3600) / 60
		if m > 0 {
			return fmt.Sprintf("%dh%dm", h, m)
		}
		return fmt.Sprintf("%dh", h)
	}
	if seconds >= 60 {
		m := seconds / 60
		s := seconds % 60
		if s > 0 {
			return fmt.Sprintf("%dm%ds", m, s)
		}
		return fmt.Sprintf("%dm", m)
	}
	return fmt.Sprintf("%ds", seconds)
}

func formatRemaining(seconds int) string {
	if seconds < 0 {
		seconds = 0
	}
	if seconds >= 3600 {
		h := seconds / 3600
		m := (seconds % 3600) / 60
		if m > 0 {
			return fmt.Sprintf("%dh %dm", h, m)
		}
		return fmt.Sprintf("%dh", h)
	}
	if seconds >= 60 {
		m := seconds / 60
		s := seconds % 60
		if s > 0 {
			return fmt.Sprintf("%dm %ds", m, s)
		}
		return fmt.Sprintf("%dm", m)
	}
	return fmt.Sprintf("%ds", seconds)
}
