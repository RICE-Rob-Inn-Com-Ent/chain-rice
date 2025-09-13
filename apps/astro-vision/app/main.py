from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, HttpUrl
import os
import uuid

app = FastAPI(title="astro-vision")

class CreateJobRequest(BaseModel):
	image_url: HttpUrl

# In-memory store for demo purposes
JOBS: dict[str, dict] = {}

@app.get("/health")
async def health():
	return {"status": "ok"}

@app.post("/jobs")
async def create_job(req: CreateJobRequest):
	job_id = str(uuid.uuid4())
	JOBS[job_id] = {"status": "queued", "image_url": str(req.image_url)}
	# TODO: enqueue celery task
	return {"id": job_id}

@app.get("/jobs/{job_id}")
async def get_job(job_id: str):
	job = JOBS.get(job_id)
	if not job:
		raise HTTPException(status_code=404, detail="job not found")
	return job