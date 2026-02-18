package main

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type alarmModel struct {
	label  string
	width  int
	height int
}

func newAlarmModel(label string) alarmModel {
	return alarmModel{label: label}
}

func (m alarmModel) Init() tea.Cmd {
	return nil
}

func (m alarmModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil
	case tea.KeyMsg:
		return m, tea.Quit
	}
	return m, nil
}

func (m alarmModel) View() string {
	title := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("3"))
	dim := lipgloss.NewStyle().Faint(true)

	content := fmt.Sprintf("%s\n\n%s",
		title.Render(fmt.Sprintf("⏰ %s timer done", m.label)),
		dim.Render("press any key"),
	)

	if m.width > 0 && m.height > 0 {
		return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, content)
	}

	return fmt.Sprintf("\n\n       %s\n\n       %s\n",
		title.Render(fmt.Sprintf("⏰ %s timer done", m.label)),
		dim.Render("press any key"),
	)
}
