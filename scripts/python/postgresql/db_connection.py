import os
import psycopg2
from configparser import ConfigParser


def get_project_root():
    return os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", "..")
    )


def load_config():
    project_root = get_project_root()
    config_file = os.path.join(project_root, "config", "postgresql.conf")

    if not os.path.exists(config_file):
        raise FileNotFoundError(f"Configuration file not found: {config_file}")

    parser = ConfigParser()
    parser.read_string("[POSTGRESQL]\n" + open(config_file).read())
    return parser["POSTGRESQL"]


def get_connection():
    config = load_config()

    connection = psycopg2.connect(
        host=config.get("postgresql_host", "localhost"),
        port=config.get("postgresql_port", "5432"),
        database=config.get("postgresql_database"),
        user=config.get("postgresql_admin_user", "postgres"),  # FIXED: was postgresql_user
        password=config.get("postgresql_admin_password", "")
    )

    return connection