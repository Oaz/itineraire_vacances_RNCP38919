from a2wsgi import ASGIMiddleware
from app import app
application = ASGIMiddleware(app)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=5000, reload=True)
