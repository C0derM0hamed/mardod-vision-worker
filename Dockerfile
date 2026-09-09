# Same runtime as production; only the model weights are added.
FROM runpod/worker-v1-vllm:v2.26.0

ENV BASE_PATH=/models \
    HF_HOME=/models/huggingface-cache/hub \
    HUGGINGFACE_HUB_CACHE=/models/huggingface-cache/hub \
    HF_DATASETS_CACHE=/models/huggingface-cache/datasets

ARG MODEL_NAME=Qwen/Qwen3-VL-4B-Instruct-FP8
ARG MODEL_REVISION=""

RUN MODEL_NAME=$MODEL_NAME MODEL_REVISION=$MODEL_REVISION \
    python3 /src/download_model.py \
    && test -f /local_model_args.json \
    && python3 -c 'import json; from pathlib import Path; path = Path(json.load(open("/local_model_args.json"))["MODEL_NAME"]); assert path.is_dir() and (path / "config.json").is_file(), path'

# Keep the inherited ENTRYPOINT: /src/main.py reads /local_model_args.json and forces Hugging Face offline mode.
