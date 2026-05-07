# This backend file contains supporting server logic.

from typing import Optional

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials

from app.security import CurrentUser, bearer_scheme, verify_bearer_token


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
) -> CurrentUser:
    return verify_bearer_token(credentials)
