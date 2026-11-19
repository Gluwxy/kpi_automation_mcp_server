from functools import lru_cache
from pathlib import Path
from urllib.parse import quote_plus

from pydantic import PostgresDsn, SecretStr, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )
    mcp_host: str = "127.0.0.1"
    mcp_port: int = 8000
    mcp_reload: bool = True

    postgres_user: str
    postgres_password: SecretStr
    postgres_db: str
    postgres_host: str = "127.0.0.1"
    postgres_port: int = 5433

    # Data Directory
    data_dir: Path = Path("data")

    @computed_field  # type: ignore[prop-decorator]
    @property
    def database_url(self) -> PostgresDsn:
        return PostgresDsn.build(
            scheme="postgresql+psycopg",
            username=self.postgres_user,
            password=quote_plus(self.postgres_password.get_secret_value()),
            host=self.postgres_host,
            port=self.postgres_port,
            path=self.postgres_db,
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
