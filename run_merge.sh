#!/bin/bash

# SRT 병합 스크립트 실행기
# 사용법: ./run_merge.sh input.srt [output_path] [threshold]
# 출력 파일은 기본적으로 output/input_stage.srt로 생성됩니다.
# 입력/출력 파일은 절대 경로 또는 상대 경로 모두 지원합니다.

set -e  # 오류 발생 시 스크립트 중단

# 스크립트 디렉토리 저장
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 현재 작업 디렉토리 저장 (스크립트 실행 시점)
ORIGINAL_PWD="$PWD"

# 프로젝트 디렉토리로 이동
cd "$SCRIPT_DIR"

# 가상환경 활성화
if [ ! -d "venv" ]; then
    echo "가상환경이 없습니다. 먼저 'python3 -m venv venv'로 생성하세요."
    exit 1
fi

source venv/bin/activate

# 인수 확인
if [ $# -lt 1 ]; then
    echo "사용법: $0 input.srt [output_path] [threshold]"
    echo "예시: $0 input.srt"
    echo "예시: $0 input.srt output.srt"
    echo "예시: $0 input.srt /custom/output/path.srt"
    echo "예시: $0 input.srt output.srt 1.5"
    echo "예시: $0 /path/to/file.srt /path/to/output.srt 2.0"
    echo "기본 출력: output/filename_stage.srt"
    echo "기본 임계값: 1.0초"
    exit 1
fi

INPUT_FILE="$1"

# 두 번째 인수가 숫자인지 확인 (임계값인지 출력 경로인지 판단)
if [[ "$2" =~ ^[0-9]*\.?[0-9]+$ ]]; then
    # 두 번째 인수가 숫자면 임계값으로 처리 (이전 버전 호환성)
    THRESHOLD="$2"
    CUSTOM_OUTPUT="$3"
else
    # 두 번째 인수가 숫자가 아니면 출력 경로로 처리
    CUSTOM_OUTPUT="$2"
    THRESHOLD="${3:-1.0}"  # 세 번째 인수가 임계값, 없으면 기본값 1.0초
fi

# 임계값이 설정되지 않았으면 기본값 사용
THRESHOLD="${THRESHOLD:-1.0}"

# 입력 파일 경로 처리
if [[ "$INPUT_FILE" = /* ]]; then
    # 절대 경로인 경우
    FULL_INPUT_PATH="$INPUT_FILE"
else
    # 상대 경로인 경우 - 스크립트 실행 시점의 현재 디렉토리 기준
    FULL_INPUT_PATH="$ORIGINAL_PWD/$INPUT_FILE"
fi

# 입력 파일 존재 확인
if [ ! -f "$FULL_INPUT_PATH" ]; then
    echo "오류: 입력 파일 '$FULL_INPUT_PATH'이 존재하지 않습니다."
    exit 1
fi

# 출력 파일 경로 처리
if [ -n "$CUSTOM_OUTPUT" ]; then
    # 사용자가 출력 경로를 지정한 경우
    if [[ "$CUSTOM_OUTPUT" = /* ]]; then
        # 절대 경로인 경우
        OUTPUT_FILE="$CUSTOM_OUTPUT"
    else
        # 상대 경로인 경우 - 스크립트 실행 시점의 현재 디렉토리 기준
        OUTPUT_FILE="$ORIGINAL_PWD/$CUSTOM_OUTPUT"
    fi
    
    # 출력 디렉토리 생성
    OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
        echo "출력 디렉토리 '$OUTPUT_DIR'를 생성했습니다."
    fi
else
    # 기본 출력 경로 사용 (스크립트 디렉토리 기준)
    DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/output"
    if [ ! -d "$DEFAULT_OUTPUT_DIR" ]; then
        mkdir -p "$DEFAULT_OUTPUT_DIR"
        echo "출력 디렉토리 '$DEFAULT_OUTPUT_DIR'를 생성했습니다."
    fi
    
    # 출력 파일명 자동 생성 (확장자 제거 후 _stage 추가하여 output 폴더에 저장)
    BASENAME=$(basename "${INPUT_FILE%.*}")
    EXTENSION="${INPUT_FILE##*.}"
    OUTPUT_FILE="${DEFAULT_OUTPUT_DIR}/${BASENAME}_stage.${EXTENSION}"
fi

echo "=== SRT 병합 시작 ==="
echo "입력 파일: $INPUT_FILE"
echo "출력 파일: $OUTPUT_FILE" 
echo "병합 임계값: ${THRESHOLD}초"
echo ""

# 스크립트 실행
python merge_srt.py "$FULL_INPUT_PATH" "$OUTPUT_FILE" --threshold "$THRESHOLD"

if [ $? -eq 0 ]; then
    echo ""
    echo "=== 병합 완료 ==="
    
    # 파일 크기 비교
    if command -v stat >/dev/null 2>&1; then
        INPUT_SIZE=$(stat -f%z "$FULL_INPUT_PATH" 2>/dev/null || echo "알 수 없음")
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
