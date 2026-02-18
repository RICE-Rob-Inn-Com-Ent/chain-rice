package data

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gocql/gocql"
)

// CassandraConsistencyLevel represents Cassandra consistency level
type CassandraConsistencyLevel string

const (
	CassandraConsistencyOne         CassandraConsistencyLevel = "ONE"
	CassandraConsistencyTwo         CassandraConsistencyLevel = "TWO"
	CassandraConsistencyThree       CassandraConsistencyLevel = "THREE"
	CassandraConsistencyQuorum      CassandraConsistencyLevel = "QUORUM"
	CassandraConsistencyAll         CassandraConsistencyLevel = "ALL"
	CassandraConsistencyLocalQuorum CassandraConsistencyLevel = "LOCAL_QUORUM"
	CassandraConsistencyEachQuorum  CassandraConsistencyLevel = "EACH_QUORUM"
	CassandraConsistencySerial      CassandraConsistencyLevel = "SERIAL"
	CassandraConsistencyLocalSerial CassandraConsistencyLevel = "LOCAL_SERIAL"
)

// CassandraConfig holds Cassandra connection configuration
type CassandraConfig struct {
	Hosts              []string
	Port               int
	Username           string
	Password           string
	Keyspace           string
	Consistency        CassandraConsistencyLevel
	NumConnections     int
	Timeout            int
	ConnectTimeout     int
	ReconnectInterval  int
	RetryPolicy        string
	Compression        string
	EnableHostDiscovery bool
	SSLEnabled         bool
	SSLCertPath        string
	SSLKeyPath         string
	SSLCAPath          string
}

// CassandraDefaultConfig returns default Cassandra configuration
func CassandraDefaultConfig() CassandraConfig {
	return CassandraConfig{
		Hosts:              []string{"localhost"},
		Port:               9042,
		Username:           "",
		Password:           "",
		Keyspace:           "default",
		Consistency:        CassandraConsistencyQuorum,
		NumConnections:     2,
		Timeout:            600,
		ConnectTimeout:     600,
		ReconnectInterval:  60,
		RetryPolicy:        "exponential",
		Compression:        "snappy",
		EnableHostDiscovery: true,
		SSLEnabled:         false,
		SSLCertPath:        "",
		SSLKeyPath:         "",
		SSLCAPath:          "",
	}
}

// CassandraFromEnv creates config from environment variables
func CassandraFromEnv() CassandraConfig {
	config := CassandraDefaultConfig()

	if cassandraURL := os.Getenv("CASSANDRA_URL"); cassandraURL != "" {
		if parsed, err := cassandraParseCassandraURL(cassandraURL); err == nil {
			config = parsed
		} else {
			log.Printf("Warning: Failed to parse CASSANDRA_URL, using individual env vars: %v", err)
		}
	}

	if hostsStr := os.Getenv("CASSANDRA_HOSTS"); hostsStr != "" {
		config.Hosts = strings.Split(hostsStr, ",")
		for i, host := range config.Hosts {
			config.Hosts[i] = strings.TrimSpace(host)
		}
	}
	if portStr := os.Getenv("CASSANDRA_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil {
			config.Port = port
		}
	}
	if username := os.Getenv("CASSANDRA_USERNAME"); username != "" {
		config.Username = username
	}
	if password := os.Getenv("CASSANDRA_PASSWORD"); password != "" {
		config.Password = password
	}
	if keyspace := os.Getenv("CASSANDRA_KEYSPACE"); keyspace != "" {
		config.Keyspace = keyspace
	} else if projectSlug := os.Getenv("PROJECT_SLUG"); projectSlug != "" {
		config.Keyspace = projectSlug
	}
	if consistency := os.Getenv("CASSANDRA_CONSISTENCY"); consistency != "" {
		config.Consistency = CassandraConsistencyLevel(strings.ToUpper(consistency))
	}
	if numConnStr := os.Getenv("CASSANDRA_NUM_CONNECTIONS"); numConnStr != "" {
		if numConn, err := strconv.Atoi(numConnStr); err == nil {
			config.NumConnections = numConn
		}
	}
	if timeoutStr := os.Getenv("CASSANDRA_TIMEOUT"); timeoutStr != "" {
		if timeout, err := strconv.Atoi(timeoutStr); err == nil {
			config.Timeout = timeout
		}
	}
	if connectTimeoutStr := os.Getenv("CASSANDRA_CONNECT_TIMEOUT"); connectTimeoutStr != "" {
		if connectTimeout, err := strconv.Atoi(connectTimeoutStr); err == nil {
			config.ConnectTimeout = connectTimeout
		}
	}
	if sslEnabledStr := os.Getenv("CASSANDRA_SSL_ENABLED"); sslEnabledStr != "" {
		config.SSLEnabled = strings.ToLower(sslEnabledStr) == "true"
	}

	return config
}

func (c CassandraConfig) ConnectionString() string {
	hostsStr := strings.Join(c.Hosts, ",")
	var auth string
	if c.Username != "" && c.Password != "" {
		auth = fmt.Sprintf("%s:%s@", url.QueryEscape(c.Username), url.QueryEscape(c.Password))
	}
	return fmt.Sprintf("cassandra://%s%s:%d/%s", auth, hostsStr, c.Port, c.Keyspace)
}

func cassandraParseCassandraURL(urlStr string) (CassandraConfig, error) {
	config := CassandraDefaultConfig()

	if !strings.HasPrefix(urlStr, "cassandra://") {
		return config, fmt.Errorf("invalid Cassandra URL format, must start with cassandra://")
	}

	u, err := url.Parse(urlStr)
	if err != nil {
		return config, fmt.Errorf("failed to parse URL: %w", err)
	}

	host := u.Hostname()
	if host != "" {
		config.Hosts = []string{host}
	}
	if u.Port() != "" {
		if port, err := strconv.Atoi(u.Port()); err == nil {
			config.Port = port
		}
	}

	if u.Path != "" {
		config.Keyspace = strings.TrimPrefix(u.Path, "/")
	}

	config.Username = u.User.Username()
	if password, ok := u.User.Password(); ok {
		config.Password = password
	}

	params := u.Query()
	if hosts := params.Get("hosts"); hosts != "" {
		config.Hosts = strings.Split(hosts, ",")
	}
	if consistency := params.Get("consistency"); consistency != "" {
		config.Consistency = CassandraConsistencyLevel(strings.ToUpper(consistency))
	}
	if ssl := params.Get("ssl"); ssl != "" {
		config.SSLEnabled = strings.ToLower(ssl) == "true"
	}

	return config, nil
}

// CassandraClient wraps the gocql.Session with additional functionality
type CassandraClient struct {
	*gocql.Session
	cluster *gocql.ClusterConfig
	config  CassandraConfig
}

// CassandraNewConnection creates a new Cassandra connection
func CassandraNewConnection(config CassandraConfig) (*CassandraClient, error) {
	cluster := gocql.NewCluster(config.Hosts...)
	cluster.Port = config.Port
	cluster.Keyspace = config.Keyspace
	
	// Convert string consistency level to gocql.Consistency
	consistency, err := gocql.ParseConsistencyWrapper(string(config.Consistency))
	if err != nil {
		// Default to Quorum if parsing fails
		consistency = gocql.Quorum
	}
	cluster.Consistency = consistency
	
	cluster.NumConns = config.NumConnections
	cluster.Timeout = time.Duration(config.Timeout) * time.Second
	cluster.ConnectTimeout = time.Duration(config.ConnectTimeout) * time.Second
	cluster.ReconnectInterval = time.Duration(config.ReconnectInterval) * time.Second

	if config.Username != "" && config.Password != "" {
		cluster.Authenticator = gocql.PasswordAuthenticator{
			Username: config.Username,
			Password: config.Password,
		}
	}

	switch config.Compression {
	case "snappy":
		cluster.Compressor = &gocql.SnappyCompressor{}
	case "lz4":
		// LZ4 compression is not directly supported in gocql
		// Use Snappy as fallback or skip compression
		// cluster.Compressor = &gocql.SnappyCompressor{}
	}

	if config.SSLEnabled {
		sslOpts := &gocql.SslOptions{
			EnableHostVerification: true,
		}
		if config.SSLCertPath != "" {
			sslOpts.CertPath = config.SSLCertPath
		}
		if config.SSLKeyPath != "" {
			sslOpts.KeyPath = config.SSLKeyPath
		}
		if config.SSLCAPath != "" {
			sslOpts.CaPath = config.SSLCAPath
		}
		cluster.SslOpts = sslOpts
	}

	switch config.RetryPolicy {
	case "exponential":
		cluster.RetryPolicy = &gocql.ExponentialBackoffRetryPolicy{
			NumRetries: 3,
			Min:        time.Second,
			Max:        10 * time.Second,
		}
	case "simple":
		cluster.RetryPolicy = &gocql.SimpleRetryPolicy{
			NumRetries: 3,
		}
	}

	// DiscoverHosts field doesn't exist in current gocql API
	// Host discovery is automatic in gocql
	// cluster.DiscoverHosts = config.EnableHostDiscovery

	session, err := cluster.CreateSession()
	if err != nil {
		return nil, fmt.Errorf("failed to create Cassandra session: %w", err)
	}

	log.Printf("Connected to Cassandra keyspace: %s", config.Keyspace)

	return &CassandraClient{
		Session: session,
		cluster: cluster,
		config:  config,
	}, nil
}

// Close closes the Cassandra connection
func (c *CassandraClient) Close() error {
	log.Println("Closing Cassandra connection")
	c.Session.Close()
	return nil
}

// HealthCheck performs a health check on Cassandra
func (c *CassandraClient) HealthCheck(ctx context.Context) error {
	query := c.Session.Query("SELECT now() FROM system.local").WithContext(ctx)
	if err := query.Exec(); err != nil {
		return fmt.Errorf("failed to ping Cassandra: %w", err)
	}
	return nil
}

// GetKeyspace returns the keyspace name
func (c *CassandraClient) GetKeyspace() string {
	return c.config.Keyspace
}

// GetConfig returns the connection configuration
func (c *CassandraClient) GetConfig() CassandraConfig {
	return c.config
}

// Query creates a new query
func (c *CassandraClient) Query(stmt string, values ...interface{}) *gocql.Query {
	return c.Session.Query(stmt, values...)
}

// ExecuteQuery executes a query and returns the result
func (c *CassandraClient) ExecuteQuery(ctx context.Context, stmt string, values ...interface{}) error {
	query := c.Session.Query(stmt, values...).WithContext(ctx)
	return query.Exec()
}

// ExecuteBatch executes a batch of queries
func (c *CassandraClient) ExecuteBatch(ctx context.Context, batch *gocql.Batch) error {
	return c.Session.ExecuteBatch(batch)
}

// CassandraKeeper manages Cassandra connections and operations
type CassandraKeeper struct {
	client *CassandraClient
}

// CassandraNewKeeper creates a new Cassandra keeper
func CassandraNewKeeper(config CassandraConfig) (*CassandraKeeper, error) {
	client, err := CassandraNewConnection(config)
	if err != nil {
		return nil, err
	}

	return &CassandraKeeper{
		client: client,
	}, nil
}

// GetClient returns the underlying Cassandra client
func (k *CassandraKeeper) GetClient() *CassandraClient {
	return k.client
}

// GetSession returns the gocql session
func (k *CassandraKeeper) GetSession() interface{} {
	return k.client.Session
}

// HealthCheck performs a health check
func (k *CassandraKeeper) HealthCheck(ctx context.Context) error {
	return k.client.HealthCheck(ctx)
}

// Close closes the connection
func (k *CassandraKeeper) Close() error {
	log.Println("Closing Cassandra connection")
	return k.client.Close()
}

// CreateKeyspace creates a keyspace if it doesn't exist
func (k *CassandraKeeper) CreateKeyspace(ctx context.Context, keyspace string, replication map[string]int) error {
	replicationStr := ""
	if replication != nil {
		replicationStr = "WITH REPLICATION = {"
		first := true
		for key, value := range replication {
			if !first {
				replicationStr += ", "
			}
			replicationStr += fmt.Sprintf("'%s': %d", key, value)
			first = false
		}
		replicationStr += "}"
	} else {
		replicationStr = "WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 3}"
	}

	stmt := fmt.Sprintf("CREATE KEYSPACE IF NOT EXISTS %s %s", keyspace, replicationStr)
	return k.client.ExecuteQuery(ctx, stmt)
}

// UseKeyspace switches to a different keyspace
func (k *CassandraKeeper) UseKeyspace(ctx context.Context, keyspace string) error {
	stmt := fmt.Sprintf("USE %s", keyspace)
	return k.client.ExecuteQuery(ctx, stmt)
}
