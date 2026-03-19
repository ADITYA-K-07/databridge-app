from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import pytesseract
from PIL import Image
import io
from groq import Groq
import json
import sqlite3
import os

app = FastAPI()

# ── Config ────────────────────────────────────
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
GROQ_API_KEY = ""  # paste your key here
DB_PATH = "databridge.db"

# ── CORS ──────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── DB helpers ────────────────────────────────
def get_db():
    return sqlite3.connect(DB_PATH)

def get_all_tables():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in cursor.fetchall()]
    conn.close()
    return tables

def get_table_data(table_name):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM {table_name}")
    columns = [desc[0] for desc in cursor.description]
    rows = cursor.fetchall()
    conn.close()
    return columns, rows

# ── Health check ──────────────────────────────
@app.get("/health")
def health():
    return {"status": "alive", "message": "DataBridge backend running"}

# ── OCR: Extract text from image ──────────────
@app.post("/extract/image")
async def extract_image(file: UploadFile = File(...)):
    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))
        extracted_text = pytesseract.image_to_string(image).strip()
        return {
            "success": True,
            "extracted_text": extracted_text if extracted_text else "No text found in image",
            "source": "tesseract",
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Voice: Transcribe audio via Groq Whisper ──
@app.post("/extract/voice")
async def extract_voice(file: UploadFile = File(...)):
    try:
        audio_bytes = await file.read()
        client = Groq(api_key=GROQ_API_KEY)
        transcription = client.audio.transcriptions.create(
            file=(file.filename, audio_bytes),
            model="whisper-large-v3",
            response_format="text"
        )
        return {
            "success": True,
            "extracted_text": transcription,
            "source": "groq_whisper",
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Document: Extract text from PDF/TXT ───────
@app.post("/extract/document")
async def extract_document(file: UploadFile = File(...)):
    try:
        file_bytes = await file.read()
        filename = file.filename.lower()

        if filename.endswith('.pdf'):
            import PyPDF2
            reader = PyPDF2.PdfReader(io.BytesIO(file_bytes))
            text = ""
            for page in reader.pages:
                text += page.extract_text() + "\n"
        else:
            text = file_bytes.decode('utf-8', errors='ignore')

        return {
            "success": True,
            "extracted_text": text.strip(),
            "source": "document",
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Spreadsheet: Extract and save all rows ────
@app.post("/extract/spreadsheet")
async def extract_spreadsheet(file: UploadFile = File(...)):
    try:
        import pandas as pd
        file_bytes = await file.read()
        filename = file.filename.lower()

        if filename.endswith('.csv'):
            df = pd.read_csv(io.BytesIO(file_bytes))
        else:
            df = pd.read_excel(io.BytesIO(file_bytes))

        # Clean column names
        df.columns = [c.lower().replace(' ', '_') for c in df.columns]

        # Save all rows directly to database
        table_name = file.filename.split('.')[0].lower().replace(' ', '_')
        conn = get_db()
        cursor = conn.cursor()

        # Create table
        col_defs = []
        for col in df.columns:
            dtype = 'INTEGER' if str(df[col].dtype) in ['int64', 'float64'] else 'TEXT'
            col_defs.append(f"{col} {dtype}")
        cursor.execute(f"CREATE TABLE IF NOT EXISTS {table_name} ({', '.join(col_defs)})")

        # Insert all rows
        for _, row in df.iterrows():
            placeholders = ', '.join(['?' for _ in df.columns])
            values = tuple(str(v) for v in row.values)
            cursor.execute(
                f"INSERT INTO {table_name} ({', '.join(df.columns)}) VALUES ({placeholders})",
                values)

        conn.commit()
        conn.close()

        text = df.to_string(index=False)
        return {
            "success": True,
            "extracted_text": text.strip(),
            "source": "spreadsheet",
            "table_name": table_name,
            "rows_saved": len(df),
            "already_saved": True,
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Schema generation via Groq ────────────────
@app.post("/schema/generate")
async def generate_schema(data: dict):
    text = data.get("text", "")
    if not text:
        return {"success": False, "error": "No text provided"}
    try:
        client = Groq(api_key=GROQ_API_KEY)
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a database schema generator. Always respond with valid JSON only. No explanation, no markdown, no backticks."
                },
                {
                    "role": "user",
                    "content": f"""Analyze this extracted text and return a JSON schema for a database table.
Return ONLY a JSON object, nothing else.
Format:
{{
  "table_name": "snake_case_name",
  "fields": [
    {{"name": "field_name", "type": "TEXT|INTEGER|REAL", "value": "extracted value or empty string"}}
  ]
}}

Text to analyze:
{text}"""
                }
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.1,
        )
        raw = chat_completion.choices[0].message.content.strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        schema = json.loads(raw)
        return {"success": True, "schema": schema}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── Save to database ──────────────────────────
@app.post("/data/save")
async def save_data(data: dict):
    schema = data.get("schema", {})
    table_name = schema.get("table_name", "extracted_data")
    fields = schema.get("fields", [])
    if not fields:
        return {"success": False, "error": "No fields to save"}
    try:
        conn = get_db()
        cursor = conn.cursor()
        col_defs = ", ".join([f"{f['name']} {f['type']}" for f in fields])
        cursor.execute(f"CREATE TABLE IF NOT EXISTS {table_name} ({col_defs})")
        col_names = ", ".join([f["name"] for f in fields])
        placeholders = ", ".join(["?" for _ in fields])
        values = tuple(f.get("value", "") for f in fields)
        cursor.execute(
            f"INSERT INTO {table_name} ({col_names}) VALUES ({placeholders})",
            values)
        conn.commit()
        conn.close()
        return {"success": True, "table": table_name, "message": f"Data saved to {table_name}"}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── Get all tables ────────────────────────────
@app.get("/database/tables")
def list_tables():
    try:
        tables = get_all_tables()
        result = []
        for table in tables:
            columns, rows = get_table_data(table)
            result.append({
                "name": table,
                "columns": columns,
                "row_count": len(rows)
            })
        return {"success": True, "tables": result}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── Get table rows ────────────────────────────
@app.get("/database/table/{table_name}")
def get_table(table_name: str):
    try:
        columns, rows = get_table_data(table_name)
        return {
            "success": True,
            "columns": columns,
            "rows": [dict(zip(columns, row)) for row in rows]
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── NL to SQL via Groq ────────────────────────
@app.post("/query/nl")
async def nl_to_sql(data: dict):
    question = data.get("question", "")
    if not question:
        return {"success": False, "error": "No question provided"}
    try:
        tables = get_all_tables()
        if not tables:
            return {"success": False, "error": "No tables in database yet"}

        schema_context = ""
        for table in tables:
            columns, _ = get_table_data(table)
            schema_context += f"Table: {table}, Columns: {', '.join(columns)}\n"

        client = Groq(api_key=GROQ_API_KEY)
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a SQL query generator. Return only the SQL query, nothing else. No explanation, no backticks."
                },
                {
                    "role": "user",
                    "content": f"""Convert this question to a SQLite SQL query.

Database schema:
{schema_context}

Question: {question}"""
                }
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.1,
        )
        sql = chat_completion.choices[0].message.content.strip()
        sql = sql.replace("```sql", "").replace("```", "").strip()

        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(sql)
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        rows = cursor.fetchall()
        conn.close()

        return {
            "success": True,
            "sql": sql,
            "columns": columns,
            "rows": [dict(zip(columns, row)) for row in rows]
        }
    except Exception as e:
        return {"success": False, "error": str(e), "sql": ""}