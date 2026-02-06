from fastapi import APIRouter
from gene1799_core.core import ping

router = APIRouter()

@router.get("/core/ping")
def core_ping():
    return ping()
