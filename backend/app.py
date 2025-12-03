from flask import Flask, request, jsonify
from flask_cors import CORS
from deep_translator import GoogleTranslator

app = Flask(__name__)

# Allow Vercel + Flutter Web + local dev
CORS(app, resources={r"/*": {"origins": "*"}})

@app.route('/translate', methods=['POST'])
def translate_text():
    try:
        # ----------------------------------------------------------
        # 1. READ REQUEST JSON
        # ----------------------------------------------------------
        data = request.json
        if not data:
            return jsonify({"error": "No data received"}), 400

        text = data.get('text', '')
        raw_source = data.get('source_lang', 'auto')
        raw_target = data.get('target_lang', 'en')

        # Clean language codes (en_US → en, hi_IN → hi, etc.)
        source_lang = (
            raw_source.split('_')[0].split('-')[0]
            if raw_source != 'auto'
            else 'auto'
        )
        target_lang = raw_target.split('_')[0].split('-')[0]

        # ----------------------------------------------------------
        # 2. VALIDATION
        # ----------------------------------------------------------
        if not text or not text.strip():
            return jsonify({"original": "", "translated": ""})

        print(f"[INPUT] '{text}'  |  {source_lang} → {target_lang}")

        # ----------------------------------------------------------
        # 3. SMALL OPTIMIZATION: SAME LANG → RETURN ORIGINAL
        # ----------------------------------------------------------
        # Only skip if source is not auto (because auto-detect may guess wrongly)
        if source_lang != "auto" and source_lang == target_lang:
            print("[SKIP] Same source and target lang — returning original.")
            return jsonify({"original": text, "translated": text})

        # ----------------------------------------------------------
        # 4. PERFORM TRANSLATION
        # ----------------------------------------------------------
        translator = GoogleTranslator(source=source_lang, target=target_lang)
        translated_text = translator.translate(text)

        print(f"[TRANSLATED] '{translated_text}'")

        return jsonify({
            "original": text,
            "translated": translated_text
        })

    except Exception as e:
        print(f"[ERROR] {e}")
        return jsonify({
            "original": text if 'text' in locals() else "",
            "translated": f"Error: {str(e)}"
        }), 500


# ----------------------------------------------------------
# 5. RENDER ENTRY POINT (Gunicorn will call this)
# ----------------------------------------------------------
# DO NOT REMOVE THIS — Render needs the `app` object.
# ----------------------------------------------------------
if __name__ == "__main__":
    # This runs only locally. Render uses gunicorn:
    # gunicorn app:app
    print("🚀 Server running locally at http://0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000, debug=True)
