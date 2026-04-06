from fastapi import APIRouter, BackgroundTasks, Depends, Response, status

from app.dependencies import get_current_user
from app.schemas import (
    AuthLoginRequest,
    AuthSignupRequest,
    AuthTokenResponse,
    GenerationCreateRequest,
    GenerationResponse,
    GenerationUpdateRequest,
    PasswordResetLinkRequest,
    PasswordResetLinkResponse,
    PlaylistCreateRequest,
    PlaylistReorderRequest,
    PlaylistResponse,
    PlaylistTrackMutationRequest,
    PlaylistUpdateRequest,
    ProfileBootstrapRequest,
    PublicGenerationResponse,
    SongResponse,
    UserProfileResponse,
)
from app.security import CurrentUser
from app.services.generation import GenerationService
from app.services.playlist import PlaylistService
from app.services.song import SongService
from app.services.user import UserService

router = APIRouter()


def generation_service() -> GenerationService:
    return GenerationService()


def playlist_service() -> PlaylistService:
    return PlaylistService()


def song_service() -> SongService:
    return SongService()


def user_service() -> UserService:
    return UserService()


@router.get("/health", tags=["health"])
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/songs", response_model=list[SongResponse], tags=["songs"])
def list_songs() -> list[SongResponse]:
    return song_service().list_songs()


@router.get("/auth/me", response_model=UserProfileResponse, tags=["auth"])
def get_me(user: CurrentUser = Depends(get_current_user)) -> UserProfileResponse:
    return user_service().get_me(user)


@router.post("/auth/signup", response_model=AuthTokenResponse, tags=["auth"])
def sign_up(payload: AuthSignupRequest) -> AuthTokenResponse:
    return user_service().sign_up(payload)


@router.post("/auth/login", response_model=AuthTokenResponse, tags=["auth"])
def sign_in(payload: AuthLoginRequest) -> AuthTokenResponse:
    return user_service().sign_in(payload)


@router.post(
    "/auth/bootstrap-profile",
    response_model=UserProfileResponse,
    tags=["auth"],
)
def bootstrap_profile(
    payload: ProfileBootstrapRequest,
    user: CurrentUser = Depends(get_current_user),
) -> UserProfileResponse:
    return user_service().bootstrap_profile(user, payload)


@router.post(
    "/auth/password-reset-link",
    response_model=PasswordResetLinkResponse,
    tags=["auth"],
)
def create_password_reset_link(
    payload: PasswordResetLinkRequest,
) -> PasswordResetLinkResponse:
    return user_service().generate_password_reset_link(payload)


@router.delete("/auth/account", status_code=status.HTTP_204_NO_CONTENT, tags=["auth"])
def delete_account(user: CurrentUser = Depends(get_current_user)) -> Response:
    user_service().delete_account(user)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/generations",
    response_model=list[GenerationResponse],
    tags=["generations"],
)
def list_generations(
    user: CurrentUser = Depends(get_current_user),
) -> list[GenerationResponse]:
    return generation_service().list_generations(user)


@router.post(
    "/generations",
    response_model=GenerationResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["generations"],
)
def create_generation(
    payload: GenerationCreateRequest,
    background_tasks: BackgroundTasks,
    user: CurrentUser = Depends(get_current_user),
) -> GenerationResponse:
    return generation_service().create_generation(user, payload, background_tasks)


@router.get(
    "/generations/{generation_id}",
    response_model=GenerationResponse,
    tags=["generations"],
)
def get_generation(
    generation_id: str,
    user: CurrentUser = Depends(get_current_user),
) -> GenerationResponse:
    return generation_service().get_generation(user, generation_id)


@router.patch(
    "/generations/{generation_id}",
    response_model=GenerationResponse,
    tags=["generations"],
)
def update_generation(
    generation_id: str,
    payload: GenerationUpdateRequest,
    user: CurrentUser = Depends(get_current_user),
) -> GenerationResponse:
    return generation_service().update_generation(user, generation_id, payload)


@router.delete(
    "/generations/{generation_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["generations"],
)
def delete_generation(
    generation_id: str,
    user: CurrentUser = Depends(get_current_user),
) -> Response:
    generation_service().delete_generation(user, generation_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/generations/{generation_id}/retry",
    response_model=GenerationResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["generations"],
)
def retry_generation(
    generation_id: str,
    background_tasks: BackgroundTasks,
    user: CurrentUser = Depends(get_current_user),
) -> GenerationResponse:
    return generation_service().retry_generation(user, generation_id, background_tasks)


@router.post(
    "/generations/{generation_id}/remix",
    response_model=GenerationResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["generations"],
)
def remix_generation(
    generation_id: str,
    payload: GenerationCreateRequest,
    background_tasks: BackgroundTasks,
    user: CurrentUser = Depends(get_current_user),
) -> GenerationResponse:
    return generation_service().remix_generation(
        user,
        generation_id,
        payload,
        background_tasks,
    )


@router.get(
    "/public/generations/{share_slug}",
    response_model=PublicGenerationResponse,
    tags=["public"],
)
def get_public_generation(share_slug: str) -> PublicGenerationResponse:
    track = generation_service().get_public_generation(share_slug)
    owner = user_service().get_me(CurrentUser(uid=track.uid))
    return PublicGenerationResponse(track=track, owner=owner)


@router.get(
    "/playlists",
    response_model=list[PlaylistResponse],
    tags=["playlists"],
)
def list_playlists(
    user: CurrentUser = Depends(get_current_user),
) -> list[PlaylistResponse]:
    return playlist_service().list_playlists(user)


@router.post(
    "/playlists",
    response_model=PlaylistResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["playlists"],
)
def create_playlist(
    payload: PlaylistCreateRequest,
    user: CurrentUser = Depends(get_current_user),
) -> PlaylistResponse:
    return playlist_service().create_playlist(user, payload)


@router.get(
    "/playlists/{playlist_id}",
    response_model=PlaylistResponse,
    tags=["playlists"],
)
def get_playlist(
    playlist_id: str,
    user: CurrentUser = Depends(get_current_user),
) -> PlaylistResponse:
    return playlist_service().get_playlist(user, playlist_id)


@router.patch(
    "/playlists/{playlist_id}",
    response_model=PlaylistResponse,
    tags=["playlists"],
)
def update_playlist(
    playlist_id: str,
    payload: PlaylistUpdateRequest,
    user: CurrentUser = Depends(get_current_user),
) -> PlaylistResponse:
    return playlist_service().update_playlist(user, playlist_id, payload)


@router.delete(
    "/playlists/{playlist_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["playlists"],
)
def delete_playlist(
    playlist_id: str,
    user: CurrentUser = Depends(get_current_user),
) -> Response:
    playlist_service().delete_playlist(user, playlist_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/playlists/{playlist_id}/tracks",
    response_model=PlaylistResponse,
    tags=["playlists"],
)
def add_track_to_playlist(
    playlist_id: str,
    payload: PlaylistTrackMutationRequest,
    user: CurrentUser = Depends(get_current_user),
) -> PlaylistResponse:
    return playlist_service().add_track(user, playlist_id, payload)


@router.delete(
    "/playlists/{playlist_id}/tracks/{track_id}",
    response_model=PlaylistResponse,
    tags=["playlists"],
)
def remove_track_from_playlist(
    playlist_id: str,
    track_id: str,
    user: CurrentUser = Depends(get_current_user),
) -> PlaylistResponse:
    return playlist_service().remove_track(user, playlist_id, track_id)


@router.post(
    "/playlists/{playlist_id}/reorder",
    response_model=PlaylistResponse,
    tags=["playlists"],
)
def reorder_playlist_tracks(
    playlist_id: str,
    payload: PlaylistReorderRequest,
    user: CurrentUser = Depends(get_current_user),
) -> PlaylistResponse:
    return playlist_service().reorder_tracks(user, playlist_id, payload)
