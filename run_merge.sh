#!/bin/bash

# SRT 병합 스크립트 실행기
# 사용법: ./run_merge.sh input.srt [threshold]
# 출력 파일은 자동으로 input_stage.srt로 생성됩니다.

set -e  # 오류 발생 시 스크립트 중단

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# 가상환경 활성화
if [ ! -d "venv" ]; then
    echo "가상환경이 없습니다. 먼저 'python3 -m venv venv'로 생성하세요."
    exit 1
fi

source venv/bin/activate

# 인수 확인
if [ $# -lt 1 ]; then
    echo "사용법: $0 input.srt [threshold]"
    echo "예시: $0 input.srt 1.0"
    echo "출력: input_stage.srt가 자동 생성됩니다."
    exit 1
fi

INPUT_FILE="$1"
THRESHOLD="${2:-1.0}"  # 기본값 1.0초 (명시적으로 설정)

# 출력 디렉토리 생성
OUTPUT_DIR="output"
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo "출력 디렉토리 '$OUTPUT_DIR'를 생성했습니다."
fi

# 출력 파일명 자동 생성 (확장자 제거 후 _stage 추가하여 output 폴더에 저장)
BASENAME=$(basename "${INPUT_FILE%.*}")
EXTENSION="${INPUT_FILE##*.}"
OUTPUT_FILE="${OUTPUT_DIR}/${BASENAME}_stage.${EXTENSION}"

# 입력 파일 존재 확인
if [ ! -f "$INPUT_FILE" ]; then
    echo "오류: 입력 파일 '$INPUT_FILE'이 존재하지 않습니다."
    exit 1
fi

echo "=== SRT 병합 시작 ==="
echo "입력 파일: $INPUT_FILE"
echo "출력 파일: $OUTPUT_FILE" 
echo "병합 임계값: ${THRESHOLD}초"
echo ""

# 스크립트 실행
python merge_srt.py "$INPUT_FILE" "$OUTPUT_FILE" --threshold "$THRESHOLD"

if [ $? -eq 0 ]; then
    echo ""
    echo "=== 병합 완료 ==="
    
    # 파일 크기 비교
    if command -v stat >/dev/null 2>&1; then
        INPUT_SIZE=$(stat -f%z "$INPUT_FILE" 2>/dev/null || echo "알 수 없음")
        OUTPUT_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || echo "알 수 없음")
        echo "원본 크기: ${INPUT_SIZE} bytes"
        echo "병합 후 크기: ${OUTPUT_SIZE} bytes"
    fi
    
    echo "출력 파일이 '$OUTPUT_FILE'에 저장되었습니다."
else
    echo ""
    echo "=== 오류 발생 ==="
    echo "병합 과정에서 문제가 발생했습니다."
    exit 1
fi
