package database

import (
	"archive/tar"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/jackc/pgx/v5"
	kpgzip "github.com/klauspost/compress/gzip"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	grpcCodes "google.golang.org/grpc/codes"
)

const (
	snapshotTracerName = "rice/database/snapshot"
	snapshotMaxRuntime = 2 * time.Hour
	defaultSnapVersion = "1"
)

var (
	snapshotTracer = otel.Tracer(snapshotTracerName)
	tablePartRe    = regexp.MustCompile(`^[a-zA-Z_][a-zA-Z0-9_]*$`)
)

// SnapshotManifest accompanies each on-disk snapshot bundle.
type SnapshotManifest struct {
	Timestamp time.Time `json:"timestamp"`
	Source    string    `json:"source"`
	Checksum  string    `json:"checksum_sha256"`
	Version   string    `json:"version"`
	Bytes     int64     `json:"bytes,omitempty"`
}

// SnapshotManager coordinates Postgres ([Pool]) and DuckDB ([Duck]) snapshot exports.
type SnapshotManager struct {
	Pool    *Pool
	Duck    *Duck
	Version string // logical snapshot schema version (defaults to [defaultSnapVersion] if empty)
}

func (m *SnapshotManager) version() string {
	if m == nil || strings.TrimSpace(m.Version) == "" {
		return defaultSnapVersion
	}
	return strings.TrimSpace(m.Version)
}

func snapErr(err error, op string) error {
	if err == nil {
		return nil
	}
	return kit.New("SNAPSHOT_FAILED", err.Error(), http.StatusInternalServerError, grpcCodes.Internal).Wrap(err, op)
}

func snapshotWorkContext(kctx *kit.Context) (context.Context, context.CancelFunc) {
	base := poolContext(kctx)
	// Long exports ignore the caller deadline but keep trace linkage until this function returns.
	detached := context.WithoutCancel(base)
	return context.WithTimeout(detached, snapshotMaxRuntime)
}

// SnapshotDuck runs EXPORT DATABASE into destPath, then produces a klauspost-gzip tar archive,
// a SHA256 manifest, and removes the raw export directory on success.
func (m *SnapshotManager) SnapshotDuck(ctx *kit.Context, destPath string) error {
	if m == nil || m.Duck == nil || m.Duck.DB() == nil {
		return snapErr(errors.New("nil duck"), "SnapshotDuck")
	}
	destPath = filepath.Clean(strings.TrimSpace(destPath))
	if destPath == "" || destPath == "." {
		return snapErr(errors.New("empty destPath"), "SnapshotDuck")
	}
	if strings.Contains(destPath, "..") {
		return snapErr(errors.New("destPath must not contain '..'"), "SnapshotDuck")
	}

	parent := poolContext(ctx)
	parent, span := snapshotTracer.Start(parent, "snapshot.duck",
		trace.WithSpanKind(trace.SpanKindInternal),
		trace.WithAttributes(attribute.String("snapshot.dest", destPath)),
	)
	defer span.End()

	workCtx, cancel := snapshotWorkContext(ctx)
	defer cancel()

	start := time.Now()
	if err := os.MkdirAll(destPath, 0o750); err != nil {
		kit.Logger().ErrorContext(parent, "snapshot: mkdir dest", "path", destPath, "err", err)
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return snapErr(err, "MkdirAll")
	}

	exportDir := filepath.Join(destPath, "duck_export")
	if err := os.RemoveAll(exportDir); err != nil {
		kit.Logger().ErrorContext(parent, "snapshot: remove stale export dir", "path", exportDir, "err", err)
	}
	if err := os.MkdirAll(exportDir, 0o750); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return snapErr(err, "MkdirAll.export")
	}

	duckSlash := filepath.ToSlash(exportDir)
	q := fmt.Sprintf(`EXPORT DATABASE '%s' (FORMAT PARQUET, COMPRESSION ZSTD);`, strings.ReplaceAll(duckSlash, `'`, `''`))
	kit.Logger().InfoContext(parent, "snapshot: EXPORT DATABASE", "path", duckSlash)

	if _, err := QueryExec(workCtx, m.Duck.DB(), q); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		_ = os.RemoveAll(exportDir)
		return snapErr(err, "duck.EXPORT_DATABASE")
	}

	archivePath := filepath.Join(destPath, "duck_snapshot.tar.gz")
	if err := os.Remove(archivePath); err != nil && !errors.Is(err, fs.ErrNotExist) {
		kit.Logger().ErrorContext(parent, "snapshot: remove old archive", "path", archivePath, "err", err)
	}

	nBytes, err := tarGzipDir(workCtx, exportDir, archivePath)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		_ = os.RemoveAll(exportDir)
		return snapErr(err, "tarGzipDir")
	}

	sum, err := sha256File(archivePath)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return snapErr(err, "sha256File")
	}

	man := SnapshotManifest{
		Timestamp: time.Now().UTC(),
		Source:    "duckdb",
		Checksum:  sum,
		Version:   m.version(),
		Bytes:     nBytes,
	}
	if err := writeManifest(filepath.Join(destPath, "manifest.json"), man); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return snapErr(err, "writeManifest")
	}

	if err := os.RemoveAll(exportDir); err != nil {
		kit.Logger().ErrorContext(parent, "snapshot: cleanup export dir failed", "path", exportDir, "err", err)
	}

	dur := time.Since(start)
	span.SetAttributes(
		attribute.Int64("snapshot.duration_ms", dur.Milliseconds()),
		attribute.Int64("snapshot.bytes_compressed", nBytes),
		attribute.String("snapshot.checksum_sha256", sum),
	)
	kit.Logger().InfoContext(parent, "snapshot: duck complete",
		"dest", destPath, "bytes", nBytes, "duration", dur.String())
	return nil
}

// DumpTable exports a single table as CSV or JSON using the pool (COPY / aggregate query).
// tableName may be "table" or "schema.table" (identifiers validated; no arbitrary SQL).
func (m *SnapshotManager) DumpTable(ctx *kit.Context, tableName, format string) ([]byte, error) {
	if m == nil || m.Pool == nil || m.Pool.inner == nil {
		return nil, snapErr(errors.New("nil pool"), "DumpTable")
	}
	ident, err := sanitizeTableIdent(tableName)
	if err != nil {
		return nil, snapErr(err, "sanitizeTableIdent")
	}
	f := strings.ToLower(strings.TrimSpace(format))
	switch f {
	case "csv", "text/csv", "json", "application/json":
	default:
		return nil, kit.BadRequest("snapshot.DumpTable: format must be csv or json")
	}

	parent := poolContext(ctx)
	parent, span := snapshotTracer.Start(parent, "snapshot.dump_table",
		trace.WithSpanKind(trace.SpanKindClient),
		trace.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("snapshot.table", tableName),
			attribute.String("snapshot.format", f),
		),
	)
	defer span.End()

	workCtx, cancel := snapshotWorkContext(ctx)
	defer cancel()

	switch f {
	case "csv", "text/csv":
		b, err := m.copyTableToBuffer(workCtx, ident, "csv")
		if err != nil {
			span.RecordError(err)
			span.SetStatus(codes.Error, err.Error())
			return nil, snapErr(err, "COPY.csv")
		}
		span.SetAttributes(attribute.Int("snapshot.row_bytes", len(b)))
		return b, nil
	case "json", "application/json":
		q := fmt.Sprintf(`SELECT coalesce(json_agg(row), '[]'::json) FROM (SELECT * FROM %s) AS row`, ident)
		var raw []byte
		if err := m.Pool.inner.QueryRow(workCtx, q).Scan(&raw); err != nil {
			span.RecordError(err)
			span.SetStatus(codes.Error, err.Error())
			return nil, snapErr(err, "json_agg")
		}
		span.SetAttributes(attribute.Int("snapshot.row_bytes", len(raw)))
		return raw, nil
	default:
		return nil, kit.Internal("snapshot.DumpTable: internal format state")
	}
}

func (m *SnapshotManager) copyTableToBuffer(ctx context.Context, quotedIdent, kind string) ([]byte, error) {
	acq, err := m.Pool.inner.Acquire(ctx)
	if err != nil {
		return nil, err
	}
	defer acq.Release()
	conn := acq.Conn()
	var buf strings.Builder
	var copySQL string
	if kind == "csv" {
		copySQL = fmt.Sprintf(`COPY %s TO STDOUT WITH (FORMAT csv, HEADER true)`, quotedIdent)
	} else {
		return nil, errors.New("copy kind not implemented")
	}
	_, err = conn.PgConn().CopyTo(ctx, &buf, copySQL)
	if err != nil {
		return nil, err
	}
	return []byte(buf.String()), nil
}

func sanitizeTableIdent(name string) (string, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		return "", errors.New("empty table name")
	}
	parts := strings.Split(name, ".")
	if len(parts) > 2 {
		return "", errors.New("only schema.table or table is allowed")
	}
	for _, p := range parts {
		if !tablePartRe.MatchString(p) {
			return "", fmt.Errorf("invalid SQL identifier segment %q", p)
		}
	}
	return pgx.Identifier(parts).Sanitize(), nil
}

func tarGzipDir(ctx context.Context, srcDir, outPath string) (written int64, err error) {
	f, err := os.Create(outPath)
	if err != nil {
		return 0, err
	}
	defer func() {
		cerr := f.Close()
		if err == nil {
			err = cerr
		}
	}()

	gw, err := kpgzip.NewWriterLevel(f, kpgzip.BestSpeed)
	if err != nil {
		return 0, err
	}
	tw := tar.NewWriter(gw)

	err = filepath.WalkDir(srcDir, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}
		if d.IsDir() {
			return nil
		}
		info, err := d.Info()
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(srcDir, path)
		if err != nil {
			return err
		}
		rel = filepath.ToSlash(rel)
		hdr, err := tar.FileInfoHeader(info, "")
		if err != nil {
			return err
		}
		hdr.Name = rel
		hdr.Size = info.Size()
		hdr.Mode = int64(info.Mode() & 0o777)
		if err := tw.WriteHeader(hdr); err != nil {
			return err
		}
		rf, err := os.Open(path)
		if err != nil {
			return err
		}
		if _, err := io.Copy(tw, rf); err != nil {
			_ = rf.Close()
			return err
		}
		if err := rf.Close(); err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		_ = tw.Close()
		_ = gw.Close()
		return 0, err
	}
	if err := tw.Close(); err != nil {
		_ = gw.Close()
		return 0, err
	}
	if err := gw.Close(); err != nil {
		return 0, err
	}
	st, err := f.Stat()
	if err != nil {
		return 0, err
	}
	return st.Size(), nil
}

func sha256File(path string) (string, error) {
	h := sha256.New()
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func writeManifest(path string, m SnapshotManifest) error {
	b, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, b, 0o640)
}
