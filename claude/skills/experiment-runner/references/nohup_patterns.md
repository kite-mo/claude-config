# Nohup 실행 패턴 및 트러블슈팅

## 기본 패턴

```bash
mkdir -p logs
nohup .venv/bin/python -u script.py [args] \
    > logs/$(date +%y%m%d_%H%M%S)_<실험명>.log 2>&1 &
echo "PID: $!"
```

### 왜 `-u` (unbuffered) 인가

python 은 stdout 이 터미널이 아니면 블록 버퍼링을 사용한다.
`-u` 없이 nohup 으로 실행하면 **로그 파일에 진행 사항이 실시간으로
남지 않는다** (과거 실제 발생한 문제). `print(..., flush=True)` 또는
환경변수 `PYTHONUNBUFFERED=1` 도 동일 효과.

## 큐 러너 패턴 (여러 실험 순차 실행)

여러 실험을 동시에 nohup 으로 던지면 GPU OOM 이 발생한다.
큐 러너 하나가 실험 목록을 순차 실행하고 진행 상황을 기록한다:

```python
# run_queue.py 핵심 구조
import json
import subprocess
from pathlib import Path

QUEUE = [
    {"name": "exp_a", "cmd": ["python", "-u", "run.py", "--seed", "42"]},
    # ...
]

progress_path = Path("progress.json")

def write_progress(data: dict) -> None:
    """원자적 기록: 임시 파일에 쓴 후 rename."""
    tmp = progress_path.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    tmp.rename(progress_path)

for i, job in enumerate(QUEUE):
    write_progress({"current": job["name"], "index": i,
                    "total": len(QUEUE), "status": "running"})
    result = subprocess.run(job["cmd"])
    status = "done" if result.returncode == 0 else "failed"
    write_progress({"current": job["name"], "index": i,
                    "total": len(QUEUE), "status": status})
```

큐 러너 자체를 nohup 으로 실행:

```bash
nohup .venv/bin/python -u run_queue.py \
    > logs/queue_gpu0.log 2>&1 &
```

## GPU 할당

```bash
# 실행 전 빈 GPU 확인
nvidia-smi --query-gpu=index,memory.used,memory.total --format=csv

# 특정 GPU 지정
CUDA_VISIBLE_DEVICES=1 nohup .venv/bin/python -u ... &
```

GPU 별로 서로 다른 큐를 배치할 때는 큐 러너를 GPU 별로 하나씩 띄운다.

## 프로세스 관리

```bash
ps aux | grep -E "python.*run_" | grep -v grep   # 확인
kill <PID>                                        # 정상 종료
tail -f logs/<파일>.log                           # 실시간 로그
```

## 재현성 체크리스트

- [ ] 전역 seed 고정 (torch / numpy / python random 모두)
- [ ] `torch.backends.cudnn.deterministic = True` 여부 명시
      (설정 시 기존 무설정 결과와 궤적이 달라지는 것은 정상)
- [ ] batch size, epochs 등 핵심 config 가 기준 세팅과 일치하는지 diff
- [ ] 결과 폴더에 사용한 config 사본 저장
- [ ] 검증 게이트: 기준값 재현 확인 후 본 실험 진행
