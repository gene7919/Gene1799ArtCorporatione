#!/usr/bin/env python3
"""
GENE1799 Publishing Pipeline Service - Port 8003
Multi-platform content publishing with scheduling and analytics.
Platforms: Twitter/X, Instagram, TikTok, YouTube, Telegram, Zora NFT
All platforms start in simulation mode (no API keys needed).
"""

import json
import os
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn

# ============================================================================
# CONFIGURATION
# ============================================================================

QUEUE_FILE = Path("media/publish_queue.json")
ANALYTICS_FILE = Path("media/publish_analytics.json")

PLATFORM_CONFIG = {
    "twitter": {
        "name": "X / Twitter",
        "max_text": 280,
        "media_formats": ["mp4", "jpg", "png", "gif"],
        "max_video_duration": 140,
        "daily_limit": 17,
        "status": "simulation"
    },
    "instagram": {
        "name": "Instagram",
        "max_text": 2200,
        "media_formats": ["mp4", "jpg"],
        "max_video_duration": 60,
        "daily_limit": 25,
        "status": "simulation"
    },
    "tiktok": {
        "name": "TikTok",
        "max_text": 2200,
        "media_formats": ["mp4"],
        "max_video_duration": 600,
        "daily_limit": 10,
        "status": "simulation"
    },
    "youtube": {
        "name": "YouTube",
        "max_text": 5000,
        "media_formats": ["mp4", "webm"],
        "max_video_duration": 43200,
        "daily_limit": 6,
        "status": "simulation"
    },
    "telegram": {
        "name": "Telegram",
        "max_text": 4096,
        "media_formats": ["mp4", "jpg", "png", "gif", "mp3"],
        "max_video_duration": 3600,
        "daily_limit": 100,
        "status": "simulation"
    },
    "zora": {
        "name": "Zora (NFT)",
        "max_text": 10000,
        "media_formats": ["mp4", "jpg", "png", "gif", "mp3", "wav"],
        "max_video_duration": None,
        "daily_limit": 50,
        "status": "simulation"
    }
}

# ============================================================================
# MODELS
# ============================================================================

class PublishRequest(BaseModel):
    content_id: str
    platforms: List[str] = ["all"]
    text: str = ""
    media_paths: List[str] = []
    hashtags: List[str] = []
    schedule_time: Optional[str] = None

class QueueItem(BaseModel):
    content_id: str
    platforms: List[str]
    text: str
    media_paths: List[str]
    hashtags: List[str]

class PlatformConnect(BaseModel):
    api_key: Optional[str] = None
    api_secret: Optional[str] = None
    access_token: Optional[str] = None
    channel_id: Optional[str] = None

# ============================================================================
# QUEUE MANAGEMENT
# ============================================================================

class PublishQueue:
    def __init__(self):
        self.queue: List[dict] = []
        self._load()

    def _load(self):
        try:
            if QUEUE_FILE.exists():
                self.queue = json.loads(QUEUE_FILE.read_text(encoding="utf-8"))
        except Exception:
            self.queue = []

    def _save(self):
        QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
        QUEUE_FILE.write_text(json.dumps(self.queue, indent=2, default=str), encoding="utf-8")

    def add(self, content_id: str, platforms: List[str], text: str,
            media_paths: List[str], hashtags: List[str],
            schedule_time: Optional[str] = None) -> dict:
        entry = {
            "id": f"pub_{uuid.uuid4().hex[:8]}",
            "content_id": content_id,
            "platforms": platforms,
            "text": text,
            "media_paths": media_paths,
            "hashtags": hashtags,
            "schedule_time": schedule_time,
            "status": "queued",
            "created_at": datetime.now().isoformat(),
            "results": {}
        }
        self.queue.append(entry)
        self._save()
        return entry

    def get_all(self) -> List[dict]:
        return self.queue

    def get_pending(self) -> List[dict]:
        return [q for q in self.queue if q["status"] == "queued"]

    def update_status(self, pub_id: str, status: str, results: dict = None):
        for item in self.queue:
            if item["id"] == pub_id:
                item["status"] = status
                if results:
                    item["results"] = results
                item["updated_at"] = datetime.now().isoformat()
                break
        self._save()

    def remove(self, pub_id: str) -> bool:
        before = len(self.queue)
        self.queue = [q for q in self.queue if q["id"] != pub_id]
        self._save()
        return len(self.queue) < before

# ============================================================================
# PLATFORM PUBLISHERS (Simulation Mode)
# ============================================================================

class PlatformPublisher:
    """Base publisher that simulates posting. Replace with real API calls when keys are added."""

    def __init__(self, platform: str, config: dict):
        self.platform = platform
        self.config = config
        self.credentials: Dict[str, str] = {}
        self.daily_count = 0

    @property
    def is_live(self) -> bool:
        return bool(self.credentials.get("api_key"))

    @property
    def can_publish(self) -> bool:
        return self.daily_count < self.config["daily_limit"]

    def connect(self, creds: dict):
        self.credentials = creds
        self.config["status"] = "connected" if creds.get("api_key") else "simulation"

    async def publish(self, text: str, media_paths: List[str], hashtags: List[str]) -> dict:
        if not self.can_publish:
            return {"success": False, "error": f"Daily limit reached ({self.config['daily_limit']})"}

        self.daily_count += 1

        # Adapt text to platform limits
        full_text = text
        if hashtags:
            tags = " ".join(f"#{h}" for h in hashtags)
            full_text = f"{text}\n\n{tags}"

        if len(full_text) > self.config["max_text"]:
            full_text = full_text[:self.config["max_text"] - 3] + "..."

        if self.is_live:
            # TODO: Replace with real API calls per platform
            return await self._real_publish(full_text, media_paths)
        else:
            return self._simulate_publish(full_text, media_paths)

    def _simulate_publish(self, text: str, media_paths: List[str]) -> dict:
        return {
            "success": True,
            "mode": "simulation",
            "platform": self.platform,
            "post_id": f"sim_{uuid.uuid4().hex[:8]}",
            "text_length": len(text),
            "media_count": len(media_paths),
            "timestamp": datetime.now().isoformat(),
            "message": f"[SIMULATION] Would publish to {self.config['name']}"
        }

    async def _real_publish(self, text: str, media_paths: List[str]) -> dict:
        # Placeholder for real API implementations
        return {
            "success": True,
            "mode": "live",
            "platform": self.platform,
            "post_id": f"live_{uuid.uuid4().hex[:8]}",
            "timestamp": datetime.now().isoformat()
        }

# ============================================================================
# ANALYTICS
# ============================================================================

class AnalyticsTracker:
    def __init__(self):
        self.records: List[dict] = []
        self._load()

    def _load(self):
        try:
            if ANALYTICS_FILE.exists():
                self.records = json.loads(ANALYTICS_FILE.read_text(encoding="utf-8"))
        except Exception:
            self.records = []

    def _save(self):
        ANALYTICS_FILE.parent.mkdir(parents=True, exist_ok=True)
        ANALYTICS_FILE.write_text(json.dumps(self.records, indent=2, default=str), encoding="utf-8")

    def record(self, platform: str, result: dict):
        self.records.append({
            "platform": platform,
            "result": result,
            "timestamp": datetime.now().isoformat()
        })
        self._save()

    def get_summary(self) -> dict:
        by_platform = {}
        for r in self.records:
            p = r["platform"]
            if p not in by_platform:
                by_platform[p] = {"total": 0, "success": 0, "failed": 0}
            by_platform[p]["total"] += 1
            if r["result"].get("success"):
                by_platform[p]["success"] += 1
            else:
                by_platform[p]["failed"] += 1

        return {
            "total_published": len(self.records),
            "by_platform": by_platform,
            "last_publish": self.records[-1]["timestamp"] if self.records else None
        }

    def get_platform(self, platform: str) -> List[dict]:
        return [r for r in self.records if r["platform"] == platform]

# ============================================================================
# FASTAPI APP
# ============================================================================

app = FastAPI(
    title="GENE1799 Publishing Pipeline",
    description="Multi-platform content publishing with scheduling and analytics",
    version="1.0.0"
)

queue = PublishQueue()
analytics = AnalyticsTracker()
publishers: Dict[str, PlatformPublisher] = {
    name: PlatformPublisher(name, cfg)
    for name, cfg in PLATFORM_CONFIG.items()
}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "GENE1799 Publishing Pipeline",
        "version": "1.0.0",
        "platforms": len(publishers),
        "queue_size": len(queue.get_pending()),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/status")
async def status():
    return {
        "service": "GENE1799 Publishing Pipeline",
        "platforms": {
            name: {
                "name": pub.config["name"],
                "status": pub.config["status"],
                "live": pub.is_live,
                "daily_count": pub.daily_count,
                "daily_limit": pub.config["daily_limit"]
            }
            for name, pub in publishers.items()
        },
        "queue": {
            "total": len(queue.get_all()),
            "pending": len(queue.get_pending())
        },
        "analytics": analytics.get_summary(),
        "timestamp": datetime.now().isoformat()
    }

# --- PLATFORMS ---

@app.get("/platforms")
async def list_platforms():
    return {
        "platforms": {
            name: {
                "name": cfg["name"],
                "status": cfg["status"],
                "max_text": cfg["max_text"],
                "media_formats": cfg["media_formats"],
                "daily_limit": cfg["daily_limit"]
            }
            for name, cfg in PLATFORM_CONFIG.items()
        }
    }

@app.post("/platforms/{platform}/connect")
async def connect_platform(platform: str, creds: PlatformConnect):
    if platform not in publishers:
        raise HTTPException(status_code=404, detail=f"Platform '{platform}' not found")
    publishers[platform].connect(creds.dict())
    return {"status": "connected", "platform": platform, "live": publishers[platform].is_live}

# --- PUBLISHING ---

@app.post("/publish")
async def publish(req: PublishRequest):
    """Publish content to specified platforms immediately."""
    target_platforms = list(publishers.keys()) if "all" in req.platforms else req.platforms
    results = {}

    for platform in target_platforms:
        if platform not in publishers:
            results[platform] = {"success": False, "error": f"Unknown platform: {platform}"}
            continue

        pub = publishers[platform]
        result = await pub.publish(req.text, req.media_paths, req.hashtags)
        results[platform] = result
        analytics.record(platform, result)

    return {
        "content_id": req.content_id,
        "platforms_targeted": len(target_platforms),
        "results": results,
        "timestamp": datetime.now().isoformat()
    }

# --- QUEUE ---

@app.post("/queue")
async def add_to_queue(req: QueueItem):
    entry = queue.add(
        req.content_id, req.platforms, req.text,
        req.media_paths, req.hashtags
    )
    return {"status": "queued", "entry": entry}

@app.get("/queue")
async def get_queue():
    return {
        "total": len(queue.get_all()),
        "pending": len(queue.get_pending()),
        "items": queue.get_all()
    }

@app.delete("/queue/{pub_id}")
async def remove_from_queue(pub_id: str):
    removed = queue.remove(pub_id)
    if not removed:
        raise HTTPException(status_code=404, detail="Queue item not found")
    return {"status": "removed", "id": pub_id}

@app.post("/queue/process")
async def process_queue():
    """Process all pending queue items."""
    pending = queue.get_pending()
    results = []

    for item in pending:
        target_platforms = list(publishers.keys()) if "all" in item["platforms"] else item["platforms"]
        item_results = {}

        for platform in target_platforms:
            if platform in publishers:
                result = await publishers[platform].publish(
                    item["text"], item["media_paths"], item.get("hashtags", [])
                )
                item_results[platform] = result
                analytics.record(platform, result)

        queue.update_status(item["id"], "published", item_results)
        results.append({"id": item["id"], "results": item_results})

    return {
        "processed": len(results),
        "results": results,
        "timestamp": datetime.now().isoformat()
    }

# --- ANALYTICS ---

@app.get("/analytics")
async def get_analytics():
    return analytics.get_summary()

@app.get("/analytics/{platform}")
async def get_platform_analytics(platform: str):
    records = analytics.get_platform(platform)
    return {
        "platform": platform,
        "total": len(records),
        "records": records[-20:]  # last 20
    }

# ============================================================================
# STARTUP
# ============================================================================

if __name__ == "__main__":
    print("""
======================================================================
   GENE1799 PUBLISHING PIPELINE SERVICE

   Starting on: http://localhost:8003

   Platforms (all in simulation mode):
     * Twitter/X      (17 posts/day)
     * Instagram       (25 posts/day)
     * TikTok         (10 videos/day)
     * YouTube        (6 uploads/day)
     * Telegram       (100 msgs/day)
     * Zora NFT       (50 mints/day)

   API Docs: http://localhost:8003/docs
======================================================================
    """)

    QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
    uvicorn.run(app, host="0.0.0.0", port=8003, reload=False, log_level="info")
