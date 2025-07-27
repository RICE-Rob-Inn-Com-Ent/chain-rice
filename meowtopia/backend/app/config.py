"""
Production-ready configuration with environment variables and secrets management.
"""
import os
import secrets
import multiprocessing
from typing import Optional, List

class Settings:
    """Application settings with production-ready configuration."""
    
    # Application
    APP_NAME: str = "Meowtopia Backend API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", secrets.token_urlsafe(32))
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))
    ALGORITHM: str = "HS256"
    
    # Password Security
    PASSWORD_RESET_TOKEN_EXPIRE_HOURS: int = int(os.getenv("PASSWORD_RESET_TOKEN_EXPIRE_HOURS", "1"))
    MIN_PASSWORD_LENGTH: int = int(os.getenv("MIN_PASSWORD_LENGTH", "8"))
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:password@db:5432/meowtopia")
    DATABASE_POOL_SIZE: int = int(os.getenv("DATABASE_POOL_SIZE", "10"))
    DATABASE_MAX_OVERFLOW: int = int(os.getenv("DATABASE_MAX_OVERFLOW", "20"))
    
    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/0")
    REDIS_CACHE_TTL: int = int(os.getenv("REDIS_CACHE_TTL", "3600"))  # 1 hour
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:3001",
        "https://meowtopia.app",
        "https://game.meowtopia.app"
    ]
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))
    RATE_LIMIT_BURST: int = int(os.getenv("RATE_LIMIT_BURST", "100"))
    
    # Email Configuration
    SMTP_HOST: Optional[str] = os.getenv("SMTP_HOST")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USERNAME: Optional[str] = os.getenv("SMTP_USERNAME")
    SMTP_PASSWORD: Optional[str] = os.getenv("SMTP_PASSWORD")
    SMTP_TLS: bool = os.getenv("SMTP_TLS", "true").lower() == "true"
    FROM_EMAIL: Optional[str] = os.getenv("FROM_EMAIL")
    
    # OpenAI Configuration
    OPENAI_API_KEY: Optional[str] = os.getenv("OPENAI_API_KEY")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")
    OPENAI_MAX_TOKENS: int = int(os.getenv("OPENAI_MAX_TOKENS", "1000"))
    
    # Sentry Configuration
    SENTRY_DSN: Optional[str] = os.getenv("SENTRY_DSN")
    SENTRY_ENVIRONMENT: str = os.getenv("SENTRY_ENVIRONMENT", "production")
    
    # File Upload
    MAX_FILE_SIZE: int = int(os.getenv("MAX_FILE_SIZE", str(10 * 1024 * 1024)))  # 10MB
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "/app/uploads")
    ALLOWED_FILE_TYPES: List[str] = [
        "image/jpeg", "image/png", "image/gif", "application/pdf"
    ]
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT: str = os.getenv("LOG_FORMAT", "json")  # json or text
    
    # Workers and Performance
    WORKER_CONNECTIONS: int = int(os.getenv("WORKER_CONNECTIONS", "1000"))
    MAX_WORKERS: int = int(os.getenv("MAX_WORKERS", "4"))
    KEEP_ALIVE: int = int(os.getenv("KEEP_ALIVE", "2"))
    
    # Health Check
    HEALTH_CHECK_INTERVAL: int = int(os.getenv("HEALTH_CHECK_INTERVAL", "30"))
    
    # Blockchain Integration
    CHAIN_RICE_RPC_URL: str = os.getenv("CHAIN_RICE_RPC_URL", "http://localhost:26657")
    CHAIN_RICE_API_URL: str = os.getenv("CHAIN_RICE_API_URL", "http://localhost:1317")
    CHAIN_RICE_GRPC_URL: str = os.getenv("CHAIN_RICE_GRPC_URL", "http://localhost:9090")
    
    # Game Configuration
    GAME_ECONOMY_FACTOR: float = float(os.getenv("GAME_ECONOMY_FACTOR", "1.0"))
    MAX_CATS_PER_USER: int = int(os.getenv("MAX_CATS_PER_USER", "100"))
    DAILY_REWARD_AMOUNT: int = int(os.getenv("DAILY_REWARD_AMOUNT", "100"))
    
    # Gunicorn Configuration
    GUNICORN_BIND: str = f"0.0.0.0:{os.getenv('PORT', '8000')}"
    GUNICORN_BACKLOG: int = int(os.getenv('GUNICORN_BACKLOG', '2048'))
    GUNICORN_WORKERS: int = int(os.getenv('WEB_CONCURRENCY', multiprocessing.cpu_count() * 2 + 1))
    GUNICORN_WORKER_CLASS: str = "uvicorn.workers.UvicornWorker"
    GUNICORN_WORKER_CONNECTIONS: int = int(os.getenv('GUNICORN_WORKER_CONNECTIONS', '1000'))
    GUNICORN_MAX_REQUESTS: int = int(os.getenv('GUNICORN_MAX_REQUESTS', '1000'))
    GUNICORN_MAX_REQUESTS_JITTER: int = int(os.getenv('GUNICORN_MAX_REQUESTS_JITTER', '50'))
    GUNICORN_PRELOAD_APP: bool = os.getenv('GUNICORN_PRELOAD_APP', 'true').lower() == 'true'
    GUNICORN_TIMEOUT: int = int(os.getenv('GUNICORN_TIMEOUT', '30'))
    GUNICORN_KEEPALIVE: int = int(os.getenv('GUNICORN_KEEPALIVE', '2'))
    GUNICORN_PROC_NAME: str = 'meowtopia_backend'
    GUNICORN_PIDFILE: str = '/tmp/gunicorn.pid'
    GUNICORN_SSL_KEYFILE: Optional[str] = os.getenv('SSL_KEYFILE')
    GUNICORN_SSL_CERTFILE: Optional[str] = os.getenv('SSL_CERTFILE')
    GUNICORN_ACCESS_LOG_FORMAT: str = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'


def get_settings() -> Settings:
    """Get settings instance."""
    return Settings()


# Create settings instance
settings = get_settings()

# Database Configuration - will be imported when sqlalchemy is available
try:
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker, declarative_base
    
    DB_USER = os.getenv("POSTGRES_USER", "postgres")
    DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres")
    DB_HOST = os.getenv("POSTGRES_HOST", "localhost")
    DB_PORT = os.getenv("POSTGRES_PORT", "5432")
    DB_NAME = os.getenv("POSTGRES_DB", "meowtopia")
    DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

    engine = create_engine(DATABASE_URL, echo=True, future=True)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base = declarative_base()
    
except ImportError:
    print("SQLAlchemy not available - database functionality disabled")
    engine = None
    SessionLocal = None
    Base = None


# Gunicorn Callback Functions
def post_fork(server, worker):
    """Called just after a worker has been forked."""
    server.log.info("Worker spawned (pid: %s)", worker.pid)


def pre_fork(server, worker):
    """Called just before a worker is forked."""
    pass


def when_ready(server):
    """Called just after the server is started."""
    server.log.info("Server is ready. Spawning workers")


def worker_int(worker):
    """Called just after a worker receives the INT or QUIT signal."""
    worker.log.info("worker received INT or QUIT signal")


def on_exit(server):
    """Called just before shutting down the server."""
    server.log.info("Server is shutting down.")
