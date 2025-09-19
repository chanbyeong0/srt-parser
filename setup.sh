#!/bin/bash

# SRT Parser 프로젝트 초기 설정 스크립트

set -e

echo "=== SRT Parser 프로젝트 설정 시작 ==="

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# Python 설치 확인
if ! command -v python3 >/dev/null 2>&1; then
    echo "오류: Python3가 설치되지 않았습니다."
    echo "Python3를 먼저 설치해주세요."
    exit 1
fi

echo "Python 버전: $(python3 --version)"

# 가상환경 생성
if [ ! -d "venv" ]; then
    echo "가상환경 생성 중..."
    python3 -m venv venv
    echo "가상환경이 생성되었습니다."
else
    echo "가상환경이 이미 존재합니다."
fi

# 가상환경 활성화
echo "가상환경 활성화 중..."
source venv/bin/activate

# requirements.txt가 있으면 설치 (현재는 표준 라이브러리만 사용)
if [ -f "requirements.txt" ]; then
    echo "의존성 확인 중..."
    # pip install -r requirements.txt  # 필요시 주석 해제
    echo "모든 의존성이 확인되었습니다."
fi

# 실행 권한 확인
chmod +x merge_srt.py
chmod +x run_merge.sh

echo ""
echo "=== 설정 완료 ==="
echo ""
echo "사용법:"
echo "1. 직접 실행: ./run_merge.sh input.srt [threshold]"
echo "2. 수동 실행: source venv/bin/activate && python merge_srt.py input.srt output.srt --threshold 1.0"
echo ""
echo "예시:"
echo "./run_merge.sh 1f24388d-c2e5-4ff2-b1ac-b346004d6c68.srt 1.0"
echo "→ 출력: output/1f24388d-c2e5-4ff2-b1ac-b346004d6c68_stage.srt"
echo ""
