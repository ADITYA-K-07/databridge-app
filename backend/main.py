from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import base64
import httpx
import os

app = FastAPI()

# Allow Flutter web to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

GOOGLE_VISION_API_KEY = "YOUR_GOOGLE_VISION_API_KEY"  # replace later

# ── Health check ──────────────────────────────
@app.get("/health")
def health():
    return {"status": "alive", "message": "DataBridge backend running"}


# ── OCR: Extract text from image ──────────────
@app.post("/extract/image")
async def extract_image(file: UploadFile = File(...)):
    try:
        # Read image bytes and encode to base64
        image_bytes = await file.read()
        image_b64 = base64.b64encode(image_bytes).decode("utf-8")

        # Call Google Vision API
        url = f"https://vision.googleapis.com/v1/images:annotate?key={GOOGLE_VISION_API_KEY}"
        payload = {
            "requests": [
                {
                    "image": {"content": image_b64},
                    "features": [{"type": "TEXT_DETECTION"}],
                }
            ]
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload)
            result = response.json()

        # Extract text from response
        annotations = result["responses"][0].get("textAnnotations", [])
        if annotations:
            extracted_text = annotations[0]["description"]
        else:
            extracted_text = ""

        return {
            "success": True,
            "extracted_text": extracted_text,
            "source": "google_vision",
        }

    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}


# ── Placeholder: Schema generation ────────────
@app.post("/schema/generate")
async def generate_schema(data: dict):
    text = data.get("text", "")
    # Claude API integration comes in Week 4
    return {
        "success": True,
        "message": "Schema generation coming in Week 4",
        "received_text": text[:100],
    }


# ── Placeholder: NL to SQL ────────────────────
@app.post("/query/nl")
async def nl_to_sql(data: dict):
    question = data.get("question", "")
    # Claude API integration comes in Week 5
    return {
        "success": True,
        "message": "NL to SQL coming in Week 5",
        "question": question,
        "sql": "SELECT * FROM table_name LIMIT 10;",
    }