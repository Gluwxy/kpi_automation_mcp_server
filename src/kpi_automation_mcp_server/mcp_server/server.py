# from fastmcp import FastMCP
# from starlette.requests import Request
# from starlette.responses import JSONResponse

# mcp = FastMCP("KPI Automation MCP Server")


# @mcp.custom_route("/health", methods=["GET"])
# async def health(_request: Request) -> JSONResponse:
#     return JSONResponse({"status": "ok"})

from mcp.server.mcpserver import MCPServer

mcp = MCPServer("KPI Automation MCP Server")
