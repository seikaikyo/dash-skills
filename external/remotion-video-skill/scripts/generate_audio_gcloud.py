#!/usr/bin/env python3
"""
Google Cloud TTS 音頻生成腳本（支援斷點續作）

特性：
- 多語言支援（zh-TW, en, ja）
- Neural2 / Wavenet 高品質語音
- 斷點續作：已存在的音檔自動跳過
- 自動更新 Remotion audioConfig.ts

用法：
    python scripts/generate_audio_gcloud.py

前置條件：
    gcloud auth login
    gcloud auth application-default login

環境變數：
    GCLOUD_PROJECT_ID: GCP 專案 ID（預設 dashai-490610）
    GCLOUD_VOICE_NAME: 語音名稱（預設依語系自動選擇）
    GCLOUD_LANG_CODE: 語言代碼（預設 cmn-TW）
    GCLOUD_SPEAKING_RATE: 語速 0.25-4.0（預設 0.95）
    GCLOUD_PITCH: 音高 -20.0~20.0（預設 -1.0）

依賴：
    gcloud CLI（已登入）
    pip install requests
"""

import base64
import json
import os
import subprocess
from pathlib import Path

import requests

PROJECT_ID = os.environ.get("GCLOUD_PROJECT_ID", "dashai-490610")
LANG_CODE = os.environ.get("GCLOUD_LANG_CODE", "cmn-TW")
SPEAKING_RATE = float(os.environ.get("GCLOUD_SPEAKING_RATE", "0.95"))
PITCH = float(os.environ.get("GCLOUD_PITCH", "-1.0"))

# 語系對應的預設語音
VOICE_MAP = {
    "cmn-TW": "cmn-TW-Wavenet-A",
    "en-US": "en-US-Neural2-D",
    "ja-JP": "ja-JP-Neural2-D",
}

VOICE_NAME = os.environ.get("GCLOUD_VOICE_NAME", VOICE_MAP.get(LANG_CODE, "cmn-TW-Wavenet-A"))

API_URL = "https://texttospeech.googleapis.com/v1/text:synthesize"

# 場景配置 - 修改這裡的內容
SCENES = [
    {"id": "01-intro", "title": "開場", "text": "歡迎觀看本期影片..."},
    {"id": "02-main", "title": "主題", "text": "今天我們來聊..."},
    {"id": "03-demo", "title": "展示", "text": "讓我們看一個例子..."},
    {"id": "04-outro", "title": "結尾", "text": "感謝觀看，下次見！"},
]

OUTPUT_DIR = Path(__file__).parent.parent / "public" / "audio"
CONFIG_FILE = Path(__file__).parent.parent / "src" / "audioConfig.ts"


def get_gcloud_token() -> str:
    """取得 gcloud access token"""
    result = subprocess.run(
        ["gcloud", "auth", "print-access-token"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise Exception("gcloud auth 失敗，請先執行 gcloud auth login")
    return result.stdout.strip()


def get_audio_duration(file_path: Path) -> float:
    """用 ffprobe 取得音檔時長"""
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(file_path)],
        capture_output=True, text=True,
    )
    return float(result.stdout.strip()) if result.stdout.strip() else 0


def generate_audio(scene: dict, token: str) -> dict:
    """使用 Google Cloud TTS API 生成音檔"""
    headers = {
        "Authorization": f"Bearer {token}",
        "x-goog-user-project": PROJECT_ID,
        "Content-Type": "application/json",
    }

    payload = {
        "input": {"text": scene["text"]},
        "voice": {"languageCode": LANG_CODE, "name": VOICE_NAME},
        "audioConfig": {
            "audioEncoding": "MP3",
            "speakingRate": SPEAKING_RATE,
            "pitch": PITCH,
        },
    }

    response = requests.post(API_URL, headers=headers, json=payload, timeout=60)

    if response.status_code != 200:
        error = response.text[:200]
        raise Exception(f"Google Cloud TTS 錯誤 ({response.status_code}): {error}")

    data = response.json()
    audio_bytes = base64.b64decode(data["audioContent"])

    output_file = OUTPUT_DIR / f"{scene['id']}.mp3"
    output_file.write_bytes(audio_bytes)

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

    content = f'''// 場景配置（Google Cloud TTS 生成）
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

    token = get_gcloud_token()

    print(f"Google Cloud TTS (Voice: {VOICE_NAME}, Lang: {LANG_CODE})")
    print(f"GCP Project: {PROJECT_ID}")
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
            result = generate_audio(scene, token)
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
