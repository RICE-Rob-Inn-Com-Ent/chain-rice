from celery import Celery
import os
import time

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
celery_app = Celery("astro_vision", broker=REDIS_URL, backend=REDIS_URL)

@celery_app.task(bind=True, autoretry_for=(Exception,), retry_backoff=True, retry_jitter=True)
def process_image(self, image_url: str) -> dict:
	# Simulacja pracy
	time.sleep(2)
	return {"image_url": image_url, "labels": ["cat", "space"], "confidence": 0.91}