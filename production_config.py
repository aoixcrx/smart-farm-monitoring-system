"""
Production Configuration for Smart Farm API
Handles logging, monitoring, and environment setup
"""

import os
import logging
from logging.handlers import RotatingFileHandler
from datetime import timedelta

# ============================================================
# ENVIRONMENT DETECTION
# ============================================================
ENV = os.getenv('FLASK_ENV', 'production')
DEBUG = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'

# ============================================================
# SECURITY CONFIGURATION
# ============================================================
SECRET_KEY = os.getenv('SECRET_KEY', 'smart_farm_secret_key_2026')
JWT_SECRET = os.getenv('JWT_SECRET', 'jwt_secret_key_2026')

# ============================================================
# DATABASE CONFIGURATION
# ============================================================
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', '200413'),
    'database': os.getenv('DB_NAME', 'smart_farm_db'),
    'pool_size': int(os.getenv('DB_POOL_SIZE', 10)),
    'pool_name': 'smartfarm_pool',
    'autocommit': False,
    'use_pure': False,
}

# ============================================================
# FIREBASE CONFIGURATION
# ============================================================
FIREBASE_CONFIG_PATH = os.getenv('FIREBASE_CONFIG_PATH', 'firebase_key.json')
FIREBASE_ENABLED = os.getenv('FIREBASE_ENABLED', 'True').lower() == 'true'

# ============================================================
# API CONFIGURATION
# ============================================================
API_HOST = os.getenv('API_HOST', '0.0.0.0')
API_PORT = int(os.getenv('API_PORT', 5000))
API_WORKERS = int(os.getenv('API_WORKERS', 4))
API_TIMEOUT = int(os.getenv('API_TIMEOUT', 120))

# ============================================================
# JWT TOKEN CONFIGURATION
# ============================================================
JWT_ACCESS_EXPIRES = timedelta(hours=1)
JWT_REFRESH_EXPIRES = timedelta(days=7)

# ============================================================
# LOGGING CONFIGURATION
# ============================================================
LOG_DIR = os.getenv('LOG_DIR', 'logs')
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
LOG_MAX_BYTES = int(os.getenv('LOG_MAX_BYTES', 10485760))  # 10MB
LOG_BACKUP_COUNT = int(os.getenv('LOG_BACKUP_COUNT', 10))

# ============================================================
# CORS CONFIGURATION
# ============================================================
CORS_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:5000',
    'http://10.0.2.2:5000',     # Android emulator
    'http://localhost:8080',     # Web
    os.getenv('ALLOWED_ORIGIN', ''),
]
CORS_ORIGINS = [origin for origin in CORS_ORIGINS if origin]

# ============================================================
# RATE LIMITING
# ============================================================
RATE_LIMIT_ENABLED = os.getenv('RATE_LIMIT_ENABLED', 'True').lower() == 'true'
RATE_LIMIT_REQUESTS = int(os.getenv('RATE_LIMIT_REQUESTS', 100))
RATE_LIMIT_WINDOW = int(os.getenv('RATE_LIMIT_WINDOW', 3600))  # 1 hour

# ============================================================
# MONITORING & ALERTING
# ============================================================
ENABLE_METRICS = os.getenv('ENABLE_METRICS', 'True').lower() == 'true'
ALERT_EMAIL = os.getenv('ALERT_EMAIL', '')
ALERT_THRESHOLD = {
    'temperature_max': float(os.getenv('ALERT_TEMP_MAX', 40.0)),
    'temperature_min': float(os.getenv('ALERT_TEMP_MIN', 10.0)),
    'humidity_max': float(os.getenv('ALERT_HUMIDITY_MAX', 95.0)),
    'humidity_min': float(os.getenv('ALERT_HUMIDITY_MIN', 20.0)),
    'stress_index_max': float(os.getenv('ALERT_STRESS_MAX', 0.8)),
}

# ============================================================
# THINGSPEAK INTEGRATION
# ============================================================
THINGSPEAK_ENABLED = os.getenv('THINGSPEAK_ENABLED', 'True').lower() == 'true'
THINGSPEAK_CHANNEL_ID = os.getenv('THINGSPEAK_CHANNEL_ID', '3211612')
THINGSPEAK_READ_KEY = os.getenv('THINGSPEAK_READ_KEY', 'DUJ1X4OCWFMWH1U0')
THINGSPEAK_WRITE_KEY = os.getenv('THINGSPEAK_WRITE_KEY', '')
THINGSPEAK_API_URL = 'https://api.thingspeak.com'
THINGSPEAK_POLL_INTERVAL = int(os.getenv('THINGSPEAK_POLL_INTERVAL', 300))  # 5 minutes

# ============================================================
# BACKUP & ARCHIVE
# ============================================================
BACKUP_ENABLED = os.getenv('BACKUP_ENABLED', 'True').lower() == 'true'
BACKUP_DIR = os.getenv('BACKUP_DIR', 'backups')
BACKUP_INTERVAL = int(os.getenv('BACKUP_INTERVAL', 86400))  # 24 hours
ARCHIVE_AFTER_DAYS = int(os.getenv('ARCHIVE_AFTER_DAYS', 90))

# ============================================================
# SETUP LOGGING SYSTEM
# ============================================================
def setup_logging():
    """Initialize production logging system"""

    # Create logs directory
    os.makedirs(LOG_DIR, exist_ok=True)

    # Get root logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, LOG_LEVEL))

    # Remove existing handlers
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)

    # Create formatters
    formatter = logging.Formatter(LOG_FORMAT, datefmt='%Y-%m-%d %H:%M:%S')

    # Console Handler (always enabled)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(getattr(logging, LOG_LEVEL))
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # File Handler (rotating)
    log_file = os.path.join(LOG_DIR, 'smartfarm.log')
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=LOG_MAX_BYTES,
        backupCount=LOG_BACKUP_COUNT
    )
    file_handler.setLevel(getattr(logging, LOG_LEVEL))
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # Error File Handler (rotating)
    error_log_file = os.path.join(LOG_DIR, 'smartfarm_errors.log')
    error_handler = RotatingFileHandler(
        error_log_file,
        maxBytes=LOG_MAX_BYTES,
        backupCount=LOG_BACKUP_COUNT
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(formatter)
    logger.addHandler(error_handler)

    # Log startup info
    logger.info("=" * 60)
    logger.info("Smart Farm API - Production Mode")
    logger.info("=" * 60)
    logger.info(f"Environment: {ENV}")
    logger.info(f"Debug Mode: {DEBUG}")
    logger.info(f"Database: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}")
    logger.info(f"Firebase: {'Enabled' if FIREBASE_ENABLED else 'Disabled'}")
    logger.info(f"Thingspeak: {'Enabled' if THINGSPEAK_ENABLED else 'Disabled'}")
    logger.info(f"Log Level: {LOG_LEVEL}")
    logger.info("=" * 60)

    return logger


# Initialize logging on import
logger = setup_logging()


# ============================================================
# CONFIGURATION VALIDATION
# ============================================================
def validate_config():
    """Validate production configuration"""
    issues = []

    # Check critical settings
    if not SECRET_KEY or SECRET_KEY == 'smart_farm_secret_key_2026':
        issues.append("⚠️  WARNING: Using default SECRET_KEY. Change in production!")

    if not JWT_SECRET or JWT_SECRET == 'jwt_secret_key_2026':
        issues.append("⚠️  WARNING: Using default JWT_SECRET. Change in production!")

    if DEBUG:
        issues.append("⚠️  WARNING: Debug mode is enabled in production!")

    if not DB_CONFIG['password']:
        issues.append("⚠️  WARNING: Database password is empty!")

    if FIREBASE_ENABLED and not os.path.exists(FIREBASE_CONFIG_PATH):
        issues.append(f"⚠️  WARNING: Firebase config not found at {FIREBASE_CONFIG_PATH}")

    # Log all issues
    if issues:
        logger.warning("Configuration Issues Found:")
        for issue in issues:
            logger.warning(f"  {issue}")

    return len(issues) == 0


# Validate configuration on startup
if ENV == 'production':
    validate_config()
