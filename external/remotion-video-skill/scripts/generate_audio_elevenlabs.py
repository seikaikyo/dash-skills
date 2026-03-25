#!/usr/bin/env python3
"""
ElevenLabs TTS 音頻生成腳本（支援斷點續作）

特性：
- 多語言支援（zh-TW, en, ja）
- 斷點續作：已存在的音檔自動跳過
- 自動更新 Remotion audioConfig.ts

用法：
    python scripts/generate_audio_elevenlabs.py

環境變數：
    ELEVENLABS_API_KEY: ElevenLabs API 金鑰（必要）
    ELEVENLABS_MODEL_ID: 模型 ID（預設 eleven_multilingual_v2）
    ELEVENLABS_VOICE_ID: 語音 ID（預設 EXAVITQu4vr4xnSDxMaL，Sarah）
    ELEVENLABS_STABILITY: 穩定度 0-1（預設 0.42）
    ELEVENLABS_SIMILARITY_BOOST: 相似度 0-1（預設 0.78）
    ELEVENLABS_STYLE: 風格 0-1（預設 0.20）

依賴：
    pip install requests
"""

import json
import os
import subprocess
from pathlib import Path

import requests

API_KEY = os.environ.get("ELEVENLABS_API_KEY")
if not API_KEY:
    print("請設定 ELEVENLABS_API_KEY 環境變數")
    exit(1)

MODEL_ID = os.environ.get("ELEVENLABS_MODEL_ID", "eleven_multilingual_v2")
VOICE_ID = os.environ.get("ELEVENLABS_VOICE_ID", "EXAVITQu4vr4xnSDxMaL")
STABILITY = float(os.environ.get("ELEVENLABS_STABILITY", "0.42"))
SIMILARITY = float(os.environ.get("ELEVENLABS_SIMILARITY_BOOST", "0.78"))
STYLE = float(os.environ.get("ELEVENLABS_STYLE", "0.20"))

API_URL = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"

# 場景配置 - 修改這裡的內容
SCENES = [
    {"id": "01-intro", "title": "開場", "text": "歡迎觀看本期影片..."},
    {"id": "02-main", "title": "主題", "text": "今天我們來聊..."},
    {"id": "03-demo", "title": "展示", "text": "讓我們看一個例子..."},
    {"id": "04-outro", "title": "結尾", "text": "感謝觀看，下次見！"},
]

OUTPUT_DIR = Path(__file__).parent.parent / "public" / "audio"
CONFIG_FILE = Path(__file__).parent.parent / "src" / "audioConfig.ts"


def get_audio_duration(file_path: Path) -> float:
    """用 ffprobe 取得音檔時長"""
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(file_path)],
        capture_output=True, text=True,
    )
    return float(result.stdout.strip()) if result.stdout.strip() else 0


def generate_audio(scene: dict) -> dict:
    """使用 ElevenLabs API 生成音檔"""
    headers = {
        "xi-api-key": API_KEY,
        "Content-Type": "application/json",
    }

    payload = {
        "text": scene["text"],
        "model_id": MODEL_ID,
        "output_format": "mp3_22050_32",
        "voice_settings": {
            "stability": STABILITY,
            "similarity_boost": SIMILARITY,
            "style": STYLE,
            "use_speaker_boost": True,
        },
    }

    response = requests.post(API_URL, headers=headers, json=payload, timeout=60)

    if response.status_code != 200:
        error = response.text[:200]
        raise Exception(f"ElevenLabs API 錯誤 ({response.status_code}): {error}")

    output_file = OUTPUT_DIR / f"{scene['id']}.mp3"
    output_file.write_bytes(response.content)

    duration = get_audio_duration(output_file)
    frames = round(duration * 30)

    return {
        "id": scene["id"],
        "title": scene["title"],
        "file": f"{scene['id']}.mp3",
        "duration": duration,
        "frames": frames,
    }


def update_config(results):
    """更新 audioConfig.ts"""
    scenes_lines = []
    for r in results:
        scene_block = f'''  {{
    id: "{r['id']}",
    title: "{r['title']}",
    durationInFrames: {r['frames']},
    audioFile: "{r['file']}",
  }}'''
        scenes_lines.append(scene_block)

    scenes_content = ",\n".join(scenes_lines)

    content = f'''// 場景配置（ElevenLabs TTS 生成）
// 自動生成，請勿手動修改

export interface SceneConfig {{
  id: string;
  title: string;
  durationInFrames: number;
  audioFile: string;
}}

export const SCENES: SceneConfig[] = [
{scenes_content},
];

export function getSceneStart(sceneIndex: number): number {{
  return SCENES.slice(0, sceneIndex).reduce((sum, s) => sum + s.durationInFrames, 0);
}}

export const TOTAL_FRAMES = SCENES.reduce((sum, s) => sum + s.durationInFrames, 0) + 60;
export const FPS = 30;
'''
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(content)


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"ElevenLabs TTS (Model: {MODEL_ID}, Voice: {VOICE_ID})")
    print(f"輸出目錄: {OUTPUT_DIR}")
    print("=" * 60)

    results = []
    skipped = 0
    generated = 0

    for i, scene in enumerate(SCENES, 1):
        output_file = OUTPUT_DIR / f"{scene['id']}.mp3"
        prefix = f"[{i}/{len(SCENES)}] {scene['id']}"

        if output_file.exists() and output_file.stat().st_size > 0:
            duration = get_audio_duration(output_file)
            frames = round(duration * 30)
            results.append({
                "id": scene["id"], "title": scene["title"],
                "file": f"{scene['id']}.mp3", "duration": duration, "frames": frames,
            })
            print(f"{prefix}: 已存在，跳過 ({duration:.2f}s)")
            skipped += 1
            continue

        print(f"{prefix}: 生成中...", end=" ", flush=True)
        try:
            result = generate_audio(scene)
            results.append(result)
            print(f"完成 {result['duration']:.2f}s ({result['frames']} frames)")
            generated += 1
        except Exception as e:
            print(f"失敗 {e}")
            print("\n生成中斷，已完成的音檔已保存，可重新執行繼續")
            return

    print("=" * 60)
    print(f"完成: {generated} 新生成, {skipped} 跳過")

    update_config(results)
    print("audioConfig.ts 已更新")


if __name__ == "__main__":
    main()
