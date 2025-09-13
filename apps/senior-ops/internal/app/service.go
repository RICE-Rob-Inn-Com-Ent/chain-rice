package app

import (
	"context"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/example/senior-ops/internal/domain"
)

// JobRepository is a hexagonal port.
type JobRepository interface {
	Save(ctx context.Context, job domain.Job) error
	Get(ctx context.Context, id domain.JobID) (domain.Job, bool, error)
}

// InMemoryRepo is a simple adapter for demonstration.
type InMemoryRepo struct {
	mu   sync.RWMutex
	data map[domain.JobID]domain.Job
}

func NewInMemoryRepo() *InMemoryRepo {
	return &InMemoryRepo{data: make(map[domain.JobID]domain.Job)}
}

func (r *InMemoryRepo) Save(ctx context.Context, job domain.Job) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.data[job.ID] = job
	return nil
}

func (r *InMemoryRepo) Get(ctx context.Context, id domain.JobID) (domain.Job, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	j, ok := r.data[id]
	return j, ok, nil
}

// Service is an application service/use-case facade.
type Service struct {
	repo JobRepository
	metricCreate prometheus.Histogram
}

func NewService(repo JobRepository, reg *prometheus.Registry) *Service {
	metricCreate := promauto.With(reg).NewHistogram(prometheus.HistogramOpts{
		Namespace: "senior_ops",
		Subsystem: "job",
		Name:      "create_duration_seconds",
		Help:      "Time to create a job",
		Buckets:   prometheus.DefBuckets,
	})
	return &Service{repo: repo, metricCreate: metricCreate}
}

func (s *Service) CreateJob(ctx context.Context, id domain.JobID, name string, now time.Time) (domain.Job, error) {
	start := time.Now()
	defer s.metricCreate.Observe(time.Since(start).Seconds())
	job, err := domain.NewJob(id, name, now)
	if err != nil {
		return domain.Job{}, err
	}
	if err := s.repo.Save(ctx, job); err != nil {
		return domain.Job{}, err
	}
	return job, nil
}

func (s *Service) GetJob(ctx context.Context, id domain.JobID) (domain.Job, bool, error) {
	return s.repo.Get(ctx, id)
}