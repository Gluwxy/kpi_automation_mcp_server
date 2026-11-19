from collections.abc import AsyncGenerator
from contextlib import AsyncExitStack, asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.responses import JSONResponse

from kpi_mcp.core.config import get_settings
from kpi_mcp.mcp_server.server import mcp

settings = get_settings()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncGenerator[None]:
    async with AsyncExitStack() as stack:
        await stack.enter_async_context(mcp.session_manager.run())
        yield


app = FastAPI(lifespan=lifespan)


@app.get("/health")
async def health() -> JSONResponse:
    return JSONResponse({"status": "healthy"})


app.mount("/", mcp.streamable_http_app())


def main() -> None:
    uvicorn.run(app, host=settings.mcp_host, port=settings.mcp_port)


if __name__ == "__main__":
    main()
