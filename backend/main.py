from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import pytesseract
from PIL import Image
import io

app = FastAPI()

# Tesseract path for Windows
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Allow Flutter web to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Health check ──────────────────────────────
@app.get("/health")
def health():
    return {"status": "alive", "message": "DataBridge backend running"}


# ── OCR: Extract text from image ──────────────
@app.post("/extract/image")
async def extract_image(file: UploadFile = File(...)):
    try:
        # Read image bytes
        image_bytes = await file.read()

        # Convert to PIL Image
        image = Image.open(io.BytesIO(image_bytes))

        # Run Tesseract OCR
        extracted_text = pytesseract.image_to_string(image)
        extracted_text = extracted_text.strip()

        return {
            "success": True,
            "extracted_text": extracted_text if extracted_text else "No text found in image",
            "source": "tesseract",
        }

    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}


# ── Placeholder: Schema generation ────────────
@app.post("/schema/generate")
async def generate_schema(data: dict):
    text = data.get("text", "")
    return {
        "success": True,
        "message": "Schema generation coming in Week 4",
        "received_text": text[:100],
    }


# ── Placeholder: NL to SQL ────────────────────
@app.post("/query/nl")
async def nl_to_sql(data: dict):
    question = data.get("question", "")
    return {
        "success": True,
        "message": "NL to SQL coming in Week 5",
        "question": question,
        "sql": "SELECT * FROM table_name LIMIT 10;",
    }