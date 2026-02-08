#!/usr/bin/env python3
"""
GENE1799 Creative Content Service - Port 8002
Generates lyrics, audio tracks, and video content using local tools.
Engines: Ollama (lyrics), edge-tts (voice), FFmpeg (audio/video composition)
"""

import asyncio
import json
import os
import uuid
import subprocess
import shutil
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List

import aiohttp
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn

# ============================================================================
# CONFIGURATION
# ============================================================================

FFMPEG_PATH = r"C:\Users\gene1\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffmpeg.exe"
OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "llama3.2:1b"
MEDIA_DIR = Path("media")
SAMPLES_DIR = Path("creative-content-service/templates/music/samples")

# Brand colors from Gene1799
BRAND_BG = "0a0e27"
BRAND_TEXT = "00ff41"
BRAND_ACCENT = "ff6600"

# ============================================================================
# PYDANTIC MODELS
# ============================================================================

class LyricsRequest(BaseModel):
    topic: str
    style: str = "pop"
    language: str = "en"
    mood: str = "inspiring"

class AudioRequest(BaseModel):
    text: str
    style: str = "ambient"
    duration: int = 30
    voice: str = "en-US-AriaNeural"

class VideoRequest(BaseModel):
    text: str
    audio_path: Optional[str] = None
    aspect: str = "vertical"
    duration: int = 30
    font_size: int = 48

class FullPipelineRequest(BaseModel):
    topic: str
    style: str = "energetic"
    language: str = "en"
    mood: str = "inspiring"
    duration: int = 30
    platforms: List[str] = ["tiktok", "instagram"]

# ============================================================================
# LYRICS ENGINE (Ollama)
# ============================================================================

class LyricsEngine:
    async def generate(self, topic: str, style: str, language: str, mood: str) -> dict:
        lang_map = {"en": "English", "it": "Italian", "es": "Spanish", "fr": "French"}
        lang_name = lang_map.get(language, language)

        prompt = (
            f"Write creative song lyrics about '{topic}'.\n"
            f"Style: {style}\n"
            f"Language: {lang_name}\n"
            f"Mood: {mood}\n"
            f"Format: 2 verses and 1 chorus. Keep it short (max 12 lines total).\n"
            f"Only output the lyrics, no explanations."
        )

        try:
            async with aiohttp.ClientSession() as session:
                payload = {
                    "model": OLLAMA_MODEL,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"temperature": 0.85, "num_predict": 300}
                }
                async with session.post(OLLAMA_URL, json=payload, timeout=aiohttp.ClientTimeout(total=60)) as resp:
                    if resp.status != 200:
                        return {"error": f"Ollama returned {resp.status}"}
                    data = await resp.json()
                    lyrics = data.get("response", "").strip()

                    # Save lyrics to file
                    lyrics_id = str(uuid.uuid4())[:8]
                    lyrics_path = MEDIA_DIR / "lyrics" / f"{lyrics_id}.txt"
                    lyrics_path.parent.mkdir(parents=True, exist_ok=True)
                    lyrics_path.write_text(lyrics, encoding="utf-8")

                    return {
                        "lyrics_id": lyrics_id,
                        "lyrics": lyrics,
                        "path": str(lyrics_path),
                        "topic": topic,
                        "style": style,
                        "language": language,
                        "model": OLLAMA_MODEL
                    }
        except Exception as e:
            return {"error": str(e)}

# ============================================================================
# AUDIO ENGINE (edge-tts + FFmpeg)
# ============================================================================

class AudioEngine:
    def __init__(self):
        self._ensure_samples()

    def _ensure_samples(self):
        """Generate basic audio samples using FFmpeg if none exist."""
        SAMPLES_DIR.mkdir(parents=True, exist_ok=True)

        samples = {
            "ambient": {"freq": 220, "type": "sine"},
            "energetic": {"freq": 440, "type": "sine"},
            "cinematic": {"freq": 165, "type": "sine"},
        }

        for name, cfg in samples.items():
            path = SAMPLES_DIR / f"{name}_loop.wav"
            if not path.exists():
                # Generate a simple tone loop with FFmpeg
                cmd = [
                    FFMPEG_PATH, "-y",
                    "-f", "lavfi", "-i",
                    f"sine=frequency={cfg['freq']}:duration=10",
                    "-af", "afade=t=in:st=0:d=1,afade=t=out:st=9:d=1,volume=0.3",
                    "-ac", "2", "-ar", "44100",
                    str(path)
                ]
                subprocess.run(cmd, capture_output=True, timeout=30)

    async def generate_tts(self, text: str, output_path: str, voice: str = "en-US-AriaNeural"):
        """Generate speech from text using edge-tts."""
        try:
            import edge_tts
            communicate = edge_tts.Communicate(text, voice)
            await communicate.save(output_path)
            return True
        except ImportError:
            # Fallback: generate silent audio
            cmd = [
                FFMPEG_PATH, "-y",
                "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
                "-t", "5", str(output_path)
            ]
            subprocess.run(cmd, capture_output=True, timeout=15)
            return False

    async def compose(self, text: str, style: str, duration: int, voice: str) -> dict:
        track_id = str(uuid.uuid4())[:8]
        audio_dir = MEDIA_DIR / "audio"
        audio_dir.mkdir(parents=True, exist_ok=True)

        tts_path = audio_dir / f"{track_id}_voice.mp3"
        output_path = audio_dir / f"{track_id}_final.mp3"

        # Step 1: Text-to-speech
        tts_ok = await self.generate_tts(text, str(tts_path), voice)

        # Step 2: Select background loop
        loop_file = SAMPLES_DIR / f"{style}_loop.wav"
        if not loop_file.exists():
            loop_file = SAMPLES_DIR / "ambient_loop.wav"

        # Step 3: Mix with FFmpeg
        if loop_file.exists() and tts_path.exists():
            cmd = [
                FFMPEG_PATH, "-y",
                "-stream_loop", "-1", "-i", str(loop_file),
                "-i", str(tts_path),
                "-filter_complex",
                "[0:a]atrim=0:{dur},asetpts=PTS-STARTPTS,volume=0.25[bg];"
                "[1:a]volume=1.0,apad[fg];"
                "[bg][fg]amix=inputs=2:duration=first:dropout_transition=2".format(dur=duration),
                "-t", str(duration),
                "-ac", "2", "-ar", "44100",
                "-b:a", "192k",
                str(output_path)
            ]
            proc = subprocess.run(cmd, capture_output=True, timeout=60)
            if proc.returncode != 0:
                # Fallback: just use the TTS
                shutil.copy2(str(tts_path), str(output_path))
        else:
            shutil.copy2(str(tts_path), str(output_path))

        return {
            "track_id": track_id,
            "path": str(output_path),
            "duration": duration,
            "tts_ok": tts_ok,
            "style": style
        }

# ============================================================================
# VIDEO ENGINE (FFmpeg)
# ============================================================================

class VideoEngine:
    async def assemble(self, text: str, audio_path: Optional[str],
                       aspect: str, duration: int, font_size: int) -> dict:
        video_id = str(uuid.uuid4())[:8]
        video_dir = MEDIA_DIR / "video"
        video_dir.mkdir(parents=True, exist_ok=True)
        output_path = video_dir / f"{video_id}_final.mp4"

        w, h = (1080, 1920) if aspect == "vertical" else (1920, 1080)

        # Split text into lines for display
        lines = [l.strip() for l in text.split("\n") if l.strip()]
        if not lines:
            lines = [text[:80]]

        # Build drawtext filter chain: show lines sequentially
        seg_duration = max(3, duration // max(len(lines), 1))
        filters = []
        for i, line in enumerate(lines[:10]):  # max 10 lines
            safe_line = line.replace("'", "").replace(":", " ").replace("\\", "")
            start_t = i * seg_duration
            end_t = start_t + seg_duration
            filters.append(
                f"drawtext=text='{safe_line}'"
                f":fontsize={font_size}:fontcolor=#{BRAND_TEXT}"
                f":x=(w-text_w)/2:y=(h-text_h)/2"
                f":enable='between(t,{start_t},{end_t})'"
                f":borderw=2:bordercolor=black"
            )

        # Add brand watermark
        filters.append(
            f"drawtext=text='Gene1799'"
            f":fontsize=24:fontcolor=#{BRAND_ACCENT}@0.6"
            f":x=w-tw-20:y=h-th-20"
        )

        vf = ",".join(filters) if filters else f"drawtext=text='Gene1799':fontsize=48:fontcolor=#{BRAND_TEXT}:x=(w-text_w)/2:y=(h-text_h)/2"

        cmd = [
            FFMPEG_PATH, "-y",
            "-f", "lavfi", "-i",
            f"color=c=#{BRAND_BG}:s={w}x{h}:d={duration}:r=24",
        ]

        if audio_path and Path(audio_path).exists():
            cmd.extend(["-i", audio_path])

        cmd.extend([
            "-vf", vf,
            "-c:v", "h264_nvenc", "-preset", "fast", "-b:v", "4M",
        ])

        if audio_path and Path(audio_path).exists():
            cmd.extend(["-c:a", "aac", "-b:a", "192k", "-shortest"])
        else:
            cmd.extend(["-t", str(duration)])

        cmd.append(str(output_path))

        proc = subprocess.run(cmd, capture_output=True, timeout=120)

        # Fallback to CPU encoding if NVENC fails
        if proc.returncode != 0:
            cmd_cpu = [c.replace("h264_nvenc", "libx264") for c in cmd]
            for i, c in enumerate(cmd_cpu):
                if c == "-b:v":
                    cmd_cpu[i+1] = "2M"
            idx = cmd_cpu.index("-preset") if "-preset" in cmd_cpu else -1
            if idx >= 0:
                cmd_cpu[idx+1] = "ultrafast"
            proc = subprocess.run(cmd_cpu, capture_output=True, timeout=120)

        if proc.returncode != 0:
            return {"error": f"FFmpeg failed: {proc.stderr.decode('utf-8', errors='replace')[-300:]}"}

        # Generate thumbnail
        thumb_path = MEDIA_DIR / "thumbnails" / f"{video_id}_thumb.jpg"
        thumb_path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([
            FFMPEG_PATH, "-y", "-i", str(output_path),
            "-ss", "1", "-frames:v", "1",
            str(thumb_path)
        ], capture_output=True, timeout=15)

        return {
            "video_id": video_id,
            "path": str(output_path),
            "thumbnail": str(thumb_path),
            "resolution": f"{w}x{h}",
            "duration": duration,
            "aspect": aspect
        }

# ============================================================================
# FASTAPI APP
# ============================================================================

app = FastAPI(
    title="GENE1799 Creative Content Service",
    description="Music, lyrics, and video generation for GENE1799",
    version="1.0.0"
)

lyrics_engine = LyricsEngine()
audio_engine = AudioEngine()
video_engine = VideoEngine()

# Track created content
content_registry: Dict[str, dict] = {}

@app.get("/health")
async def health():
    ffmpeg_ok = Path(FFMPEG_PATH).exists()
    return {
        "status": "healthy" if ffmpeg_ok else "degraded",
        "service": "GENE1799 Creative Content Service",
        "version": "1.0.0",
        "engines": {
            "lyrics": "ollama (llama3.2:1b)",
            "tts": "edge-tts",
            "audio": "ffmpeg",
            "video": "ffmpeg + nvenc"
        },
        "ffmpeg": ffmpeg_ok,
        "timestamp": datetime.now().isoformat()
    }

@app.get("/status")
async def status():
    # Check Ollama
    ollama_ok = False
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get("http://localhost:11434/api/tags", timeout=aiohttp.ClientTimeout(total=3)) as resp:
                ollama_ok = resp.status == 200
    except Exception:
        pass

    return {
        "service": "GENE1799 Creative Content Service",
        "ollama": "connected" if ollama_ok else "disconnected",
        "ffmpeg": Path(FFMPEG_PATH).exists(),
        "media_dir": str(MEDIA_DIR.absolute()),
        "content_created": len(content_registry),
        "timestamp": datetime.now().isoformat()
    }

# --- LYRICS ---

@app.post("/create/lyrics")
async def create_lyrics(req: LyricsRequest):
    result = await lyrics_engine.generate(req.topic, req.style, req.language, req.mood)
    if "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])
    content_registry[result["lyrics_id"]] = {"type": "lyrics", **result}
    return result

# --- AUDIO ---

@app.post("/create/audio")
async def create_audio(req: AudioRequest):
    result = await audio_engine.compose(req.text, req.style, req.duration, req.voice)
    if "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])
    content_registry[result["track_id"]] = {"type": "audio", **result}
    return result

# --- VIDEO ---

@app.post("/create/video")
async def create_video(req: VideoRequest):
    result = await video_engine.assemble(
        req.text, req.audio_path, req.aspect, req.duration, req.font_size
    )
    if "error" in result:
        raise HTTPException(status_code=500, detail=result["error"])
    content_registry[result["video_id"]] = {"type": "video", **result}
    return result

# --- FULL PIPELINE ---

@app.post("/create/full")
async def create_full(req: FullPipelineRequest):
    """Full pipeline: lyrics -> audio -> video."""
    pipeline_id = str(uuid.uuid4())[:8]
    results = {"pipeline_id": pipeline_id, "steps": {}}

    # Step 1: Generate lyrics
    lyrics_result = await lyrics_engine.generate(req.topic, req.style, req.language, req.mood)
    if "error" in lyrics_result:
        raise HTTPException(status_code=500, detail=f"Lyrics failed: {lyrics_result['error']}")
    results["steps"]["lyrics"] = lyrics_result

    # Step 2: Generate audio from lyrics
    voice_map = {"en": "en-US-AriaNeural", "it": "it-IT-ElsaNeural", "es": "es-ES-ElviraNeural", "fr": "fr-FR-DeniseNeural"}
    voice = voice_map.get(req.language, "en-US-AriaNeural")
    audio_result = await audio_engine.compose(lyrics_result["lyrics"], req.style, req.duration, voice)
    if "error" in audio_result:
        raise HTTPException(status_code=500, detail=f"Audio failed: {audio_result['error']}")
    results["steps"]["audio"] = audio_result

    # Step 3: Generate video with lyrics + audio
    aspect = "vertical" if any(p in req.platforms for p in ["tiktok", "instagram"]) else "horizontal"
    video_result = await video_engine.assemble(
        lyrics_result["lyrics"], audio_result["path"], aspect, req.duration, 42
    )
    if "error" in video_result:
        raise HTTPException(status_code=500, detail=f"Video failed: {video_result['error']}")
    results["steps"]["video"] = video_result

    results["status"] = "completed"
    results["timestamp"] = datetime.now().isoformat()
    results["summary"] = {
        "topic": req.topic,
        "lyrics_file": lyrics_result["path"],
        "audio_file": audio_result["path"],
        "video_file": video_result["path"],
        "thumbnail": video_result.get("thumbnail", ""),
        "platforms": req.platforms,
        "ready_to_publish": True
    }

    content_registry[pipeline_id] = {"type": "full_pipeline", **results}
    return results

# --- MEDIA FILES ---

@app.get("/media/{content_id}")
async def get_media(content_id: str):
    if content_id in content_registry:
        info = content_registry[content_id]
        path = info.get("path", "")
        if path and Path(path).exists():
            return FileResponse(path)
    raise HTTPException(status_code=404, detail="Content not found")

@app.get("/content")
async def list_content():
    return {
        "count": len(content_registry),
        "items": [
            {"id": k, "type": v.get("type", "unknown")}
            for k, v in content_registry.items()
        ]
    }

# ============================================================================
# STARTUP
# ============================================================================

if __name__ == "__main__":
    print("""
======================================================================
   GENE1799 CREATIVE CONTENT SERVICE

   Starting on: http://localhost:8002

   Engines:
     * Lyrics: Ollama (llama3.2:1b)
     * Voice: edge-tts (Microsoft Neural TTS)
     * Audio: FFmpeg (mix + compose)
     * Video: FFmpeg + NVENC (GPU accelerated)

   API Docs: http://localhost:8002/docs
======================================================================
    """)

    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    for sub in ["audio", "video", "thumbnails", "lyrics"]:
        (MEDIA_DIR / sub).mkdir(parents=True, exist_ok=True)

    uvicorn.run(app, host="0.0.0.0", port=8002, reload=False, log_level="info")
