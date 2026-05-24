package web

// SMTP via go-mail with mandatory or opportunistic TLS (STARTTLS) for encrypted transport.
// Postal/Mailpit and other hosts share the same configuration surface.

import (
	"context"
	"crypto/tls"
	"errors"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/wneessen/go-mail"
)

const (
	EnvSMTPHost     = "RICE_SMTP_HOST"
	EnvSMTPPort     = "RICE_SMTP_PORT"
	EnvSMTPUser     = "RICE_SMTP_USER"
	EnvSMTPPassword = "RICE_SMTP_PASSWORD"
	EnvSMTPFrom     = "RICE_SMTP_FROM"
	EnvSMTPRetries  = "RICE_SMTP_RETRIES"
	// EnvSMTPTLS selects TLS behavior: mandatory (default), opportunistic, none (e.g. local Mailpit).
	EnvSMTPTLS = "RICE_SMTP_TLS"
)

// MailConfig selects Postal (production) vs Mailpit (dev) via SMTP host/port and credentials.
type MailConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
}

// MailConfigFromEnv loads [MailConfig] from [EnvSMTPHost], [EnvSMTPPort], etc. Host must be set.
func MailConfigFromEnv() MailConfig {
	port, _ := strconv.Atoi(strings.TrimSpace(os.Getenv(EnvSMTPPort)))
	return MailConfig{
		Host:     strings.TrimSpace(os.Getenv(EnvSMTPHost)),
		Port:     port,
		Username: strings.TrimSpace(os.Getenv(EnvSMTPUser)),
		Password: strings.TrimSpace(os.Getenv(EnvSMTPPassword)),
		From:     strings.TrimSpace(os.Getenv(EnvSMTPFrom)),
	}
}

// NewMailClient builds an SMTP client (Postal exposes SMTP; Mailpit listens on 1025 in dev).
func NewMailClient(cfg MailConfig) (*mail.Client, error) {
	if cfg.Host == "" {
		return nil, errors.New("web: mail host required")
	}
	port := cfg.Port
	if port == 0 {
		port = 587
	}
	return mail.NewClient(cfg.Host, mail.WithPort(port),
		mail.WithSMTPAuth(mail.SMTPAuthPlain),
		mail.WithUsername(cfg.Username),
		mail.WithPassword(cfg.Password),
	)
}

// NewSecureMailClient is like [NewMailClient] but applies TLS policy from [EnvSMTPTLS] or explicit policy,
// and upgrades the TLS config (ServerName, minimum TLS 1.2).
func NewSecureMailClient(cfg MailConfig, policy mail.TLSPolicy) (*mail.Client, error) {
	if cfg.Host == "" {
		return nil, errors.New("web: mail host required")
	}
	port := cfg.Port
	if port == 0 {
		port = 587
	}
	if env := strings.TrimSpace(os.Getenv(EnvSMTPTLS)); env != "" {
		policy = parseMailTLSPolicy(env)
	}
	tlsCfg := &tls.Config{
		ServerName:         cfg.Host,
		MinVersion:         tls.VersionTLS12,
		InsecureSkipVerify: false,
	}
	opts := []mail.Option{
		mail.WithPort(port),
		mail.WithSMTPAuth(mail.SMTPAuthPlain),
		mail.WithUsername(cfg.Username),
		mail.WithPassword(cfg.Password),
		mail.WithTLSPolicy(policy),
		mail.WithTLSConfig(tlsCfg),
	}
	return mail.NewClient(cfg.Host, opts...)
}

func parseMailTLSPolicy(s string) mail.TLSPolicy {
	switch strings.ToLower(s) {
	case "none", "off", "no":
		return mail.NoTLS
	case "opportunistic", "auto":
		return mail.TLSOpportunistic
	default:
		return mail.TLSMandatory
	}
}

// SendHTML sends an HTML body to recipients over the current connection policy.
func SendHTML(ctx context.Context, c *mail.Client, from string, to []string, subject, htmlBody string) error {
	if c == nil {
		return errors.New("web: nil mail client")
	}
	if from == "" {
		return errors.New("web: mail from required")
	}
	m := mail.NewMsg()
	if err := m.From(from); err != nil {
		return err
	}
	for _, addr := range to {
		if err := m.To(addr); err != nil {
			return err
		}
	}
	m.Subject(subject)
	m.SetBodyString(mail.TypeTextHTML, htmlBody)
	return c.DialAndSendWithContext(ctx, m)
}

// SendMailWithRetry sends msg with up to maxAttempts tries on failure (minimum 1).
func SendMailWithRetry(ctx context.Context, c *mail.Client, msg *mail.Msg, maxAttempts int) error {
	if c == nil {
		return errors.New("web: nil mail client")
	}
	if msg == nil {
		return errors.New("web: nil mail message")
	}
	if maxAttempts < 1 {
		maxAttempts = 1
	}
	var last error
	for i := 0; i < maxAttempts; i++ {
		last = c.DialAndSendWithContext(ctx, msg)
		if last == nil {
			return nil
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(time.Duration(i+1) * 200 * time.Millisecond):
		}
	}
	return last
}

// SMTPRetriesFromEnv returns [EnvSMTPRetries] or default 3.
func SMTPRetriesFromEnv() int {
	n, err := strconv.Atoi(strings.TrimSpace(os.Getenv(EnvSMTPRetries)))
	if err != nil || n < 1 {
		return 3
	}
	return n
}
