import os
import psycopg
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="3-Tier Todo Backend", version="1.0")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://todo:todo123@localhost:5432/todo")

class TodoCreate(BaseModel):
    title: str

class TodoUpdate(BaseModel):
    title: str | None = None
    completed: bool | None = None

def db():
    return psycopg.connect(DATABASE_URL)

@app.get("/health")
def health():
    try:
        with db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": "unavailable", "error": str(e)}

@app.get("/todos")
def list_todos():
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id,title,completed,created_at FROM todos ORDER BY id")
            rows = cur.fetchall()
    return [{"id":r[0],"title":r[1],"completed":r[2],"created_at":r[3].isoformat()} for r in rows]

@app.post("/todos", status_code=201)
def create_todo(todo: TodoCreate):
    title = todo.title.strip()
    if not title:
        raise HTTPException(400, "title is required")
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO todos(title) VALUES(%s) RETURNING id,title,completed,created_at", (title,))
            r = cur.fetchone()
        conn.commit()
    return {"id":r[0],"title":r[1],"completed":r[2],"created_at":r[3].isoformat()}

@app.put("/todos/{todo_id}")
def update_todo(todo_id: int, todo: TodoUpdate):
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id,title,completed,created_at FROM todos WHERE id=%s", (todo_id,))
            old = cur.fetchone()
            if not old:
                raise HTTPException(404, "todo not found")
            title = todo.title.strip() if todo.title is not None else old[1]
            completed = todo.completed if todo.completed is not None else old[2]
            cur.execute(
                "UPDATE todos SET title=%s,completed=%s WHERE id=%s RETURNING id,title,completed,created_at",
                (title, completed, todo_id))
            r = cur.fetchone()
        conn.commit()
    return {"id":r[0],"title":r[1],"completed":r[2],"created_at":r[3].isoformat()}

@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int):
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM todos WHERE id=%s RETURNING id", (todo_id,))
            r = cur.fetchone()
        conn.commit()
    if not r:
        raise HTTPException(404, "todo not found")
    return {"deleted": r[0]}
