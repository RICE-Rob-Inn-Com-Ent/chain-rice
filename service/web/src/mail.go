package web

// TODO:
// [ ] implement go-mail SMTP client:
//     NewMailer() *mail.Client
//     SMTP host from RICE_SMTP_HOST env var
//     SMTP port from RICE_SMTP_PORT env var
//     Postal in prod, Mailpit in dev — same config, different host
// [ ] implement email sending:
//     Send(ctx, msg *mail.Msg) error — with OTel span
//     retry on SMTP error: max RICE_SMTP_RETRIES attempts
// [ ] implement email templates:
//     templates from RICE_EMAIL_TEMPLATE_DIR env var
//     never hardcode HTML in Go code
// [ ] implement email audit:
//     every sent email → append to NATS audit.smith.email subject

import (
	"context"
	"errors"

	"github.com/wneessen/go-mail"
)

// MailConfig selects Postal (production) vs Mailpit (dev) via SMTP host/port and optional TLS.
type MailConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
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

// SendHTML sends an HTML body to recipients.
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
