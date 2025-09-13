package domain

import (
	"errors"
	"time"
)

var (
	ErrInvalidJob = errors.New("invalid job")
)

type JobID string

type Job struct {
	ID        JobID
	Name      string
	CreatedAt time.Time
}

func NewJob(id JobID, name string, now time.Time) (Job, error) {
	if id == "" || name == "" {
		return Job{}, ErrInvalidJob
	}
	return Job{ID: id, Name: name, CreatedAt: now}, nil
}