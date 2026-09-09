# Mardod baked vision worker

This is the source for a custom RunPod serverless vLLM image that uses the same
`runpod/worker-v1-vllm:v2.26.0` runtime as production and includes
`Qwen/Qwen3-VL-4B-Instruct-FP8` in the image. The stock worker downloads roughly
4.5 GB from Hugging Face during a cold start; baking the snapshot removes that
download from worker startup. Model initialization and image pulls can still take
time.

The image's build uses the stock worker's `/src/download_model.py`, writes
`/local_model_args.json`, and verifies the baked snapshot before the build can
succeed. The inherited `/src/main.py` reads that file and forces Hugging Face
offline mode at runtime. No Hugging Face token is needed for this public model.

## Build in the sibling repository

The sibling repository is `C0derM0hamed/mardod-vision-worker`. Copy this
`Dockerfile` to that repository's root and copy
`.github/workflows/build.yml` to its `.github/workflows/build.yml`, preserving
both files verbatim. Then commit and push to `main`; the workflow frees runner
disk space, builds with Buildx, and streams the image layers to GHCR.

The resulting pinned image is:

```text
ghcr.io/c0derm0hamed/mardod-vision-worker:2.26.0-qwen3vl4b-fp8
```

## RunPod template settings

Use the pinned image tag above and a 40 GB container disk. Set exactly these
environment variables:

```text
MAX_MODEL_LEN=8192
MAX_NUM_SEQS=4
GPU_MEMORY_UTILIZATION=0.92
OPENAI_SERVED_MODEL_NAME_OVERRIDE=vision
```

Do not set `MODEL_NAME`: the baked `/local_model_args.json` path is authoritative.
Do not add a model cache volume or an HF token for this image. The endpoint keeps
using the `vision` model name on the OpenAI-compatible route.

When upgrading, bump `runpod/worker-v1-vllm` in the Dockerfile together with the
corresponding baked-worker image tag. The base runtime and published tag must be
kept in sync, then rebuilt and pushed as a new version.

## Rollback

Switch the endpoint back to the existing stock-image template `38xd0hpjet`.
That template stays unchanged; use its existing stock-image settings when rolling
back.
