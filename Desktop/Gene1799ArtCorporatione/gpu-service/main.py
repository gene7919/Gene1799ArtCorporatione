#!/usr/bin/env python3
"""
GENE1799 GPU Service - Port 4000
Real GPU monitoring and rendering using NVIDIA RTX 4070 Super.
Provides: GPU metrics, image generation, video encoding, visual effects.
"""

import asyncio
import json
import os
import subprocess
import time
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn

# ============================================================================
# CONFIGURATION
# ============================================================================

FFMPEG_PATH = r"C:\Users\gene1\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffmpeg.exe"
MEDIA_DIR = Path(__file__).parent.parent / "media"
RENDER_DIR = MEDIA_DIR / "renders"
RENDER_DIR.mkdir(parents=True, exist_ok=True)

# Brand colors
BRAND_BG = "#0a0e27"
BRAND_GREEN = "#00ff41"
BRAND_ORANGE = "#ff6600"
BRAND_WHITE = "#ffffff"

# GPU Monitoring
try:
    import pynvml as nvml
    nvml.nvmlInit()
    GPU_HANDLE = nvml.nvmlDeviceGetHandleByIndex(0)
    GPU_AVAILABLE = True
    GPU_NAME = nvml.nvmlDeviceGetName(GPU_HANDLE)
    if isinstance(GPU_NAME, bytes):
        GPU_NAME = GPU_NAME.decode("utf-8")
except Exception:
    GPU_AVAILABLE = False
    GPU_HANDLE = None
    GPU_NAME = "No GPU detected"

# Image generation
try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
    PILLOW_AVAILABLE = True
except ImportError:
    PILLOW_AVAILABLE = False

# ============================================================================
# APP
# ============================================================================

app = FastAPI(
    title="GENE1799 GPU Service",
    version="1.0.0",
    description="Real GPU monitoring and rendering - RTX 4070 Super"
)

# Task tracking
gpu_tasks: Dict[str, Dict] = {}

# ============================================================================
# PYDANTIC MODELS
# ============================================================================

class ImageRequest(BaseModel):
    type: str = "thumbnail"  # thumbnail, banner, social_card, cover
    title: str = "GENE1799"
    subtitle: Optional[str] = None
    width: int = 1080
    height: int = 1080
    style: str = "default"  # default, neon, minimal, gradient
    text_color: Optional[str] = None
    bg_color: Optional[str] = None

class VideoRequest(BaseModel):
    input_path: str
    output_format: str = "mp4"
    codec: str = "h264_nvenc"  # h264_nvenc, hevc_nvenc, libx264
    resolution: Optional[str] = None  # e.g., "1920x1080"
    bitrate: str = "4M"
    preset: str = "fast"  # fast, medium, slow (NVENC presets)

class EffectRequest(BaseModel):
    input_path: str
    effects: List[str] = ["brand_watermark"]  # brand_watermark, blur, glow, vignette, grayscale
    watermark_text: str = "GENE1799"
    output_format: str = "png"

# ============================================================================
# GPU MONITORING
# ============================================================================

def get_gpu_info() -> Dict[str, Any]:
    """Get detailed GPU hardware info."""
    if not GPU_AVAILABLE:
        return {"available": False, "name": "No GPU", "error": "pynvml not initialized"}

    try:
        mem = nvml.nvmlDeviceGetMemoryInfo(GPU_HANDLE)
        driver = nvml.nvmlSystemGetDriverVersion()
        if isinstance(driver, bytes):
            driver = driver.decode("utf-8")

        try:
            cuda_ver = nvml.nvmlSystemGetCudaDriverVersion_v2()
            cuda_str = f"{cuda_ver // 1000}.{(cuda_ver % 1000) // 10}"
        except Exception:
            cuda_str = "unknown"

        try:
            power = nvml.nvmlDeviceGetPowerUsage(GPU_HANDLE) / 1000.0
            power_limit = nvml.nvmlDeviceGetPowerManagementLimit(GPU_HANDLE) / 1000.0
        except Exception:
            power = 0
            power_limit = 0

        try:
            clock_gpu = nvml.nvmlDeviceGetClockInfo(GPU_HANDLE, 0)  # graphics clock
            clock_mem = nvml.nvmlDeviceGetClockInfo(GPU_HANDLE, 1)  # memory clock
        except Exception:
            clock_gpu = 0
            clock_mem = 0

        try:
            fan = nvml.nvmlDeviceGetFanSpeed(GPU_HANDLE)
        except Exception:
            fan = -1

        return {
            "available": True,
            "name": GPU_NAME,
            "driver_version": driver,
            "cuda_version": cuda_str,
            "architecture": "Ada Lovelace",
            "compute_capability": "8.9",
            "memory": {
                "total_mb": round(mem.total / (1024 ** 2)),
                "used_mb": round(mem.used / (1024 ** 2)),
                "free_mb": round(mem.free / (1024 ** 2)),
                "utilization_pct": round(mem.used / mem.total * 100, 1)
            },
            "power": {
                "current_watts": round(power, 1),
                "limit_watts": round(power_limit, 1)
            },
            "clocks": {
                "gpu_mhz": clock_gpu,
                "memory_mhz": clock_mem
            },
            "fan_speed_pct": fan if fan >= 0 else "N/A",
            "encoders": ["h264_nvenc", "hevc_nvenc"],
            "capabilities": ["fp32", "fp16", "int8", "tensor-core", "nvenc", "nvdec", "cuda"]
        }
    except Exception as e:
        return {"available": True, "name": GPU_NAME, "error": str(e)}


def get_gpu_metrics() -> Dict[str, Any]:
    """Get real-time GPU metrics."""
    if not GPU_AVAILABLE:
        return {"available": False}

    try:
        mem = nvml.nvmlDeviceGetMemoryInfo(GPU_HANDLE)
        util = nvml.nvmlDeviceGetUtilizationRates(GPU_HANDLE)
        temp = nvml.nvmlDeviceGetTemperature(GPU_HANDLE, 0)

        try:
            power = nvml.nvmlDeviceGetPowerUsage(GPU_HANDLE) / 1000.0
        except Exception:
            power = 0

        try:
            procs = nvml.nvmlDeviceGetComputeRunningProcesses(GPU_HANDLE)
            proc_count = len(procs)
        except Exception:
            proc_count = 0

        return {
            "available": True,
            "gpu_name": GPU_NAME,
            "temperature_c": temp,
            "gpu_utilization_pct": util.gpu,
            "memory_utilization_pct": util.memory,
            "vram": {
                "total_mb": round(mem.total / (1024 ** 2)),
                "used_mb": round(mem.used / (1024 ** 2)),
                "free_mb": round(mem.free / (1024 ** 2)),
            },
            "power_watts": round(power, 1),
            "active_processes": proc_count,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {"available": False, "error": str(e)}

# ============================================================================
# IMAGE GENERATION
# ============================================================================

def _hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color to RGB tuple."""
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def _get_font(size: int):
    """Get a font, falling back to default if custom not available."""
    font_paths = [
        r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\calibri.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                continue
    return ImageFont.load_default()


def generate_image(req: ImageRequest) -> Dict[str, Any]:
    """Generate a branded image."""
    if not PILLOW_AVAILABLE:
        raise HTTPException(500, "Pillow not available")

    render_id = uuid.uuid4().hex[:8]
    bg = _hex_to_rgb(req.bg_color or BRAND_BG)
    text_col = _hex_to_rgb(req.text_color or BRAND_GREEN)

    img = Image.new("RGB", (req.width, req.height), bg)
    draw = ImageDraw.Draw(img)

    if req.style == "gradient":
        # Vertical gradient from dark to brand color
        accent = _hex_to_rgb(BRAND_ORANGE)
        for y in range(req.height):
            ratio = y / req.height
            r = int(bg[0] * (1 - ratio) + accent[0] * ratio * 0.3)
            g = int(bg[1] * (1 - ratio) + accent[1] * ratio * 0.3)
            b = int(bg[2] * (1 - ratio) + accent[2] * ratio * 0.3)
            draw.line([(0, y), (req.width, y)], fill=(r, g, b))

    elif req.style == "neon":
        # Neon glow grid effect
        grid_color = _hex_to_rgb(BRAND_GREEN)
        dim_grid = tuple(c // 6 for c in grid_color)
        spacing = 60
        for x in range(0, req.width, spacing):
            draw.line([(x, 0), (x, req.height)], fill=dim_grid, width=1)
        for y in range(0, req.height, spacing):
            draw.line([(0, y), (req.width, y)], fill=dim_grid, width=1)
        # Corner accents
        accent_col = _hex_to_rgb(BRAND_ORANGE)
        draw.rectangle([(0, 0), (4, req.height)], fill=accent_col)
        draw.rectangle([(req.width - 4, 0), (req.width, req.height)], fill=accent_col)
        draw.rectangle([(0, 0), (req.width, 4)], fill=accent_col)
        draw.rectangle([(0, req.height - 4), (req.width, req.height)], fill=accent_col)

    elif req.style == "minimal":
        # Subtle bottom bar
        bar_h = req.height // 15
        draw.rectangle(
            [(0, req.height - bar_h), (req.width, req.height)],
            fill=_hex_to_rgb(BRAND_ORANGE)
        )

    # Draw title
    title_size = min(req.width, req.height) // 8
    title_font = _get_font(title_size)
    bbox = draw.textbbox((0, 0), req.title, font=title_font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    title_y = (req.height - th) // 2 - (title_size // 2 if req.subtitle else 0)
    draw.text(
        ((req.width - tw) // 2, title_y),
        req.title,
        fill=text_col,
        font=title_font
    )

    # Draw subtitle
    if req.subtitle:
        sub_size = title_size // 2
        sub_font = _get_font(sub_size)
        bbox = draw.textbbox((0, 0), req.subtitle, font=sub_font)
        sw = bbox[2] - bbox[0]
        draw.text(
            ((req.width - sw) // 2, title_y + th + sub_size // 2),
            req.subtitle,
            fill=_hex_to_rgb(BRAND_ORANGE),
            font=sub_font
        )

    # Brand watermark bottom-right
    wm_font = _get_font(max(16, min(req.width, req.height) // 30))
    wm_text = "GENE1799"
    bbox = draw.textbbox((0, 0), wm_text, font=wm_font)
    wm_w = bbox[2] - bbox[0]
    draw.text(
        (req.width - wm_w - 20, req.height - 40),
        wm_text,
        fill=(*_hex_to_rgb(BRAND_GREEN), 180),
        font=wm_font
    )

    # Determine output format and path
    ext = "png" if req.type in ["thumbnail", "social_card"] else "jpg"
    out_path = RENDER_DIR / f"{render_id}.{ext}"
    img.save(str(out_path), quality=95 if ext == "jpg" else None)

    # Generate preset sizes if social_card
    variants = {}
    if req.type == "social_card":
        sizes = {
            "instagram_square": (1080, 1080),
            "instagram_story": (1080, 1920),
            "twitter_header": (1500, 500),
            "youtube_thumb": (1280, 720),
        }
        for name, (w, h) in sizes.items():
            resized = img.resize((w, h), Image.LANCZOS)
            vp = RENDER_DIR / f"{render_id}_{name}.{ext}"
            resized.save(str(vp), quality=95 if ext == "jpg" else None)
            variants[name] = str(vp)

    return {
        "render_id": render_id,
        "path": str(out_path),
        "width": req.width,
        "height": req.height,
        "style": req.style,
        "type": req.type,
        "variants": variants if variants else None,
        "timestamp": datetime.now().isoformat()
    }

# ============================================================================
# VIDEO RENDERING (NVENC)
# ============================================================================

def render_video(req: VideoRequest) -> Dict[str, Any]:
    """GPU-accelerated video encode/transcode."""
    render_id = uuid.uuid4().hex[:8]
    input_path = Path(req.input_path)

    if not input_path.exists():
        raise HTTPException(404, f"Input file not found: {req.input_path}")

    out_name = f"{render_id}_encoded.{req.output_format}"
    out_path = RENDER_DIR / out_name

    # Build FFmpeg command with NVENC
    cmd = [
        FFMPEG_PATH, "-y",
        "-i", str(input_path),
    ]

    if req.resolution:
        cmd.extend(["-s", req.resolution])

    # Try NVENC first
    use_nvenc = req.codec in ("h264_nvenc", "hevc_nvenc")
    if use_nvenc:
        cmd.extend([
            "-c:v", req.codec,
            "-preset", req.preset,
            "-b:v", req.bitrate,
            "-c:a", "aac", "-b:a", "192k",
            str(out_path)
        ])
    else:
        cmd.extend([
            "-c:v", "libx264",
            "-preset", "fast",
            "-b:v", req.bitrate,
            "-c:a", "aac", "-b:a", "192k",
            str(out_path)
        ])

    start = time.time()
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=300,
            encoding="utf-8", errors="replace"
        )
        elapsed = round(time.time() - start, 2)

        if result.returncode != 0 and use_nvenc:
            # Fallback to CPU encoding
            cmd_cpu = [c.replace("h264_nvenc", "libx264").replace("hevc_nvenc", "libx265") for c in cmd]
            result = subprocess.run(
                cmd_cpu, capture_output=True, text=True, timeout=300,
                encoding="utf-8", errors="replace"
            )
            elapsed = round(time.time() - start, 2)
            actual_codec = "libx264 (CPU fallback)"
        else:
            actual_codec = req.codec

        if result.returncode != 0:
            raise HTTPException(500, f"FFmpeg failed: {result.stderr[-500:]}")

        file_size = out_path.stat().st_size

        return {
            "render_id": render_id,
            "path": str(out_path),
            "codec": actual_codec,
            "resolution": req.resolution or "original",
            "bitrate": req.bitrate,
            "file_size_bytes": file_size,
            "file_size_mb": round(file_size / (1024 ** 2), 2),
            "encoding_time_sec": elapsed,
            "gpu_accelerated": "nvenc" in actual_codec,
            "timestamp": datetime.now().isoformat()
        }

    except subprocess.TimeoutExpired:
        raise HTTPException(504, "Video encoding timed out (5 min limit)")


# ============================================================================
# IMAGE EFFECTS
# ============================================================================

def apply_effects(req: EffectRequest) -> Dict[str, Any]:
    """Apply visual effects to an image."""
    if not PILLOW_AVAILABLE:
        raise HTTPException(500, "Pillow not available")

    input_path = Path(req.input_path)
    if not input_path.exists():
        raise HTTPException(404, f"Input file not found: {req.input_path}")

    render_id = uuid.uuid4().hex[:8]
    img = Image.open(str(input_path)).convert("RGB")
    draw = ImageDraw.Draw(img)

    applied = []

    for effect in req.effects:
        if effect == "brand_watermark":
            wm_font = _get_font(max(20, img.width // 20))
            bbox = draw.textbbox((0, 0), req.watermark_text, font=wm_font)
            wm_w = bbox[2] - bbox[0]
            # Semi-transparent watermark
            overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
            od = ImageDraw.Draw(overlay)
            od.text(
                (img.width - wm_w - 30, img.height - 60),
                req.watermark_text,
                fill=(*_hex_to_rgb(BRAND_GREEN), 130),
                font=wm_font
            )
            img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
            draw = ImageDraw.Draw(img)
            applied.append("brand_watermark")

        elif effect == "blur":
            img = img.filter(ImageFilter.GaussianBlur(radius=5))
            draw = ImageDraw.Draw(img)
            applied.append("blur")

        elif effect == "glow":
            # Brighten edges for glow effect
            bright = img.filter(ImageFilter.EDGE_ENHANCE_MORE)
            img = Image.blend(img, bright, 0.3)
            draw = ImageDraw.Draw(img)
            applied.append("glow")

        elif effect == "vignette":
            # Manual vignette via darkening corners
            w, h = img.size
            vignette = Image.new("RGB", (w, h), (0, 0, 0))
            mask = Image.new("L", (w, h), 0)
            md = ImageDraw.Draw(mask)
            # Ellipse in center = white (keep bright), corners stay dark
            md.ellipse([w // 6, h // 6, w - w // 6, h - h // 6], fill=255)
            mask = mask.filter(ImageFilter.GaussianBlur(radius=w // 5))
            img = Image.composite(img, vignette, mask)
            draw = ImageDraw.Draw(img)
            applied.append("vignette")

        elif effect == "grayscale":
            img = img.convert("L").convert("RGB")
            draw = ImageDraw.Draw(img)
            applied.append("grayscale")

    out_path = RENDER_DIR / f"{render_id}_fx.{req.output_format}"
    img.save(str(out_path), quality=95)

    return {
        "render_id": render_id,
        "path": str(out_path),
        "effects_applied": applied,
        "width": img.width,
        "height": img.height,
        "timestamp": datetime.now().isoformat()
    }


# ============================================================================
# ENDPOINTS
# ============================================================================

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "GENE1799 GPU Service",
        "gpu": GPU_NAME if GPU_AVAILABLE else "CPU-only mode",
        "gpu_available": GPU_AVAILABLE,
        "pillow_available": PILLOW_AVAILABLE
    }


@app.get("/status")
async def status():
    metrics = get_gpu_metrics()
    return {
        "service": "GENE1799 GPU Service",
        "version": "1.0.0",
        "port": 4000,
        "gpu": metrics,
        "capabilities": {
            "monitoring": GPU_AVAILABLE,
            "image_generation": PILLOW_AVAILABLE,
            "nvenc_encoding": GPU_AVAILABLE,
            "effects": PILLOW_AVAILABLE
        },
        "task_count": len(gpu_tasks),
        "render_dir": str(RENDER_DIR),
        "uptime": datetime.now().isoformat()
    }


@app.get("/gpu/info")
async def gpu_info():
    return get_gpu_info()


@app.get("/gpu/metrics")
async def gpu_metrics():
    return get_gpu_metrics()


@app.post("/render/image")
async def render_image(req: ImageRequest, background_tasks: BackgroundTasks):
    task_id = uuid.uuid4().hex[:8]
    gpu_tasks[task_id] = {"status": "processing", "type": "image", "started": datetime.now().isoformat()}

    try:
        result = generate_image(req)
        gpu_tasks[task_id] = {"status": "completed", "type": "image", "result": result}
        return result
    except Exception as e:
        gpu_tasks[task_id] = {"status": "failed", "type": "image", "error": str(e)}
        raise


@app.post("/render/video")
async def render_video_endpoint(req: VideoRequest, background_tasks: BackgroundTasks):
    task_id = uuid.uuid4().hex[:8]
    gpu_tasks[task_id] = {"status": "processing", "type": "video", "started": datetime.now().isoformat()}

    try:
        result = render_video(req)
        gpu_tasks[task_id] = {"status": "completed", "type": "video", "result": result}
        return result
    except Exception as e:
        gpu_tasks[task_id] = {"status": "failed", "type": "video", "error": str(e)}
        raise


@app.post("/render/effect")
async def render_effect(req: EffectRequest):
    task_id = uuid.uuid4().hex[:8]
    gpu_tasks[task_id] = {"status": "processing", "type": "effect", "started": datetime.now().isoformat()}

    try:
        result = apply_effects(req)
        gpu_tasks[task_id] = {"status": "completed", "type": "effect", "result": result}
        return result
    except Exception as e:
        gpu_tasks[task_id] = {"status": "failed", "type": "effect", "error": str(e)}
        raise


@app.get("/tasks")
async def list_tasks():
    return {"tasks": gpu_tasks, "count": len(gpu_tasks)}


@app.get("/tasks/{task_id}")
async def get_task(task_id: str):
    if task_id not in gpu_tasks:
        raise HTTPException(404, f"Task {task_id} not found")
    return gpu_tasks[task_id]


@app.get("/renders/{render_id}")
async def get_render(render_id: str):
    """Serve a rendered file."""
    for f in RENDER_DIR.iterdir():
        if f.stem.startswith(render_id):
            return FileResponse(str(f))
    raise HTTPException(404, f"Render {render_id} not found")


# ============================================================================
# STARTUP
# ============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("  GENE1799 GPU Service")
    print(f"  GPU: {GPU_NAME if GPU_AVAILABLE else 'CPU-only mode'}")
    if GPU_AVAILABLE:
        m = get_gpu_metrics()
        print(f"  VRAM: {m['vram']['used_mb']}MB / {m['vram']['total_mb']}MB")
        print(f"  Temperature: {m['temperature_c']}C")
    print(f"  Pillow: {'OK' if PILLOW_AVAILABLE else 'NOT AVAILABLE'}")
    print(f"  Renders: {RENDER_DIR}")
    print("=" * 60)
    print("  Starting on http://0.0.0.0:4000")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=4000, reload=False)
