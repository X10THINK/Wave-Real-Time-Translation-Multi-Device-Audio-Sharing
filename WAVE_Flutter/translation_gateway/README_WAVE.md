# Sihan Member 3 gateway, now bundled inside WAVE 6.3

Original contribution: `BT-SHARE-Sihan-Member-3.zip`, `experiments/ai-translation/gateway/`.

Use `python -m uvicorn gateway.app:app --host 0.0.0.0 --port 8098` from this `translation_gateway` directory after installing `requirements.txt`. Set server-side `OPENAI_API_KEY` and `BT_DEV_GATEWAY_TOKEN` for development. The endpoint is `/v1/stream`. The gateway is **a development POC**; production authentication, pricing, privacy, rate limiting, audio efficiency and model lifecycle must be reviewed separately.

See `../docs/V6_3_SIHAN_TRANSLATION_INTEGRATION.md` for full command examples, truth in UI, and verified vs pending work.
