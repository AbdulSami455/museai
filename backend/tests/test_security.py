import os

from fastapi.security import HTTPAuthorizationCredentials

from app.config import get_settings
from app.security import verify_bearer_token


def test_verify_bearer_token_accepts_dev_token():
    os.environ["ALLOW_INSECURE_DEV_TOKENS"] = "true"
    get_settings.cache_clear()

    credentials = HTTPAuthorizationCredentials(
        scheme="Bearer",
        credentials="dev:user-123:user@example.com",
    )

    user = verify_bearer_token(credentials)

    assert user.uid == "user-123"
    assert user.email == "user@example.com"

    os.environ["ALLOW_INSECURE_DEV_TOKENS"] = "false"
    get_settings.cache_clear()
