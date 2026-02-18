package main

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type tickMsg time.Time

type model struct {
	timers []*Timer
	input  textinput.Model
	err    string
	done   bool
}

func newModel() model {
	ti := textinput.New()
	ti.Prompt = "› "
	ti.PromptStyle = lipgloss.NewStyle().Bold(true)
	ti.Focus()

	return model{
		timers: loadAllTimers(),
		input:  ti,
	}
}

func tick() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func (m model) Init() tea.Cmd {
	return tea.Batch(textinput.Blink, tick())
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			m.done = true
			return m, tea.Quit
		case tea.KeyEnter:
			return m.submit()
		}
		m.err = ""
	case tickMsg:
		m.timers = loadAllTimers()
		return m, tick()
	}

	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m model) submit() (tea.Model, tea.Cmd) {
	val := strings.TrimSpace(m.input.Value())
	if val == "" {
		m.done = true
		return m, tea.Quit
	}

	if len(val) >= 2 && (val[0] == 'd' || val[0] == 'D') {
		idx := 0
		valid := true
		for _, c := range val[1:] {
			if c >= '0' && c <= '9' {
				idx = idx*10 + int(c-'0')
			} else {
				valid = false
				break
			}
		}
		if valid && idx >= 1 && idx <= len(m.timers) {
			cancelTimer(m.timers[idx-1])
			m.done = true
			return m, tea.Quit
		}
		m.err = "invalid timer number"
		m.input.Reset()
		return m, nil
	}

	seconds, err := parseDuration(val)
	if err != nil {
		m.err = err.Error()
		m.input.Reset()
		return m, nil
	}

	if err := createTimer(seconds); err != nil {
		m.err = err.Error()
		m.input.Reset()
		return m, nil
	}

	m.done = true
	return m, tea.Quit
}

func (m model) View() string {
	if m.done {
		return ""
	}

	dim := lipgloss.NewStyle().Faint(true)
	num := lipgloss.NewStyle().Foreground(lipgloss.Color("3"))
	errSty := lipgloss.NewStyle().Foreground(lipgloss.Color("1"))

	var b strings.Builder
	b.WriteString("\n")

	if len(m.timers) == 0 {
		b.WriteString("  " + dim.Render("(no active timers)") + "\n")
	} else {
		now := time.Now().Unix()
		for i, t := range m.timers {
			rem := int(t.FireAt - now)
			if rem < 0 {
				rem = 0
			}
			b.WriteString(fmt.Sprintf("  %s %s left    %s\n",
				num.Render(fmt.Sprintf("%d.", i+1)),
				formatRemaining(rem),
				dim.Render("("+t.Label+")"),
			))
		}
	}

	b.WriteString("\n")
	hints := "5 · 30s · 1h30m"
	if len(m.timers) > 0 {
		hints += " · d1 cancel"
	}
	b.WriteString("  " + dim.Render(hints) + "\n")
	b.WriteString("  " + m.input.View())
	if m.err != "" {
		b.WriteString("  " + errSty.Render(m.err))
	}
	b.WriteString("\n")

	return b.String()
}
