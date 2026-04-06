from fastapi.security import HTTPAuthorizationCredentials

from app.security import verify_bearer_token


def test_verify_bearer_token_accepts_dev_token():
    credentials = HTTPAuthorizationCredentials(
        scheme="Bearer",
        credentials="dev:user-123:user@example.com",
    )

    user = verify_bearer_token(credentials)

    assert user.uid == "user-123"
    assert user.email == "user@example.com"
