# SRT Parser - 자막 병합 도구

SRT 자막 파일의 인접한 블록들을 지능적으로 병합하여 더 읽기 쉬운 자막을 만드는 Python 도구입니다.

## ✨ 주요 기능

- **인접 블록 병합**: 설정된 임계값(기본 1초) 이하의 간격을 가진 자막 블록들을 자동으로 병합
- **한 글자 자막 제거**: 한 글자만 있는 불필요한 자막 블록을 자동으로 삭제
- **시간 제한**: 병합된 블록이 2분을 넘지 않도록 제한하여 적절한 길이 유지
- **자동 파일명 생성**: 입력 파일명에 `_stage` 접미사를 붙여 `output/` 폴더에 자동 저장
- **가상환경 지원**: Python 가상환경을 통한 깔끔한 의존성 관리

## 🚀 빠른 시작

### 1. 프로젝트 설정
```bash
# 저장소 클론 후 초기 설정
./setup.sh
```

### 2. 자막 파일 병합
```bash
# 기본 설정으로 병합 (1초 임계값, 2분 제한)
./run_merge.sh input.srt

# 사용자 정의 임계값으로 병합
./run_merge.sh input.srt 2.0
```

### 3. 결과 확인
```
input.srt → output/input_stage.srt
```

## 📋 병합 규칙

### 기본 규칙
- **간격 계산**: `다음_블록_시작시간 - 현재_블록_종료시간`
- **병합 조건**: `0 ≤ 간격 ≤ 임계값(초)`
- **겹침 제외**: 음수 간격(겹치는 블록)은 병합하지 않음

### 추가 제한사항
- **한 글자 제거**: 실제 글자 수가 1개인 블록은 자동 삭제
- **시간 제한**: 병합된 블록의 총 시간이 2분을 넘으면 병합 중단
- **번호 유지**: 첫 번째 블록의 번호를 유지하고 병합된 블록들은 삭제

## 🛠️ 사용법

### 간편 실행
```bash
# 기본값 사용 (1초 임계값)
./run_merge.sh input.srt

# 다른 임계값 사용
./run_merge.sh input.srt 1.5

# 절대 경로 사용
./run_merge.sh /path/to/your/file.srt 2.0

# 다른 디렉토리에서 실행 (상대 경로)
cd /Users/mago/Downloads
/path/to/srt_parser/run_merge.sh subfolder/input.srt
```

### 수동 실행
```bash
# 가상환경 활성화
source venv/bin/activate

# 기본 옵션
python merge_srt.py input.srt output.srt

# 모든 옵션 사용
python merge_srt.py input.srt output.srt \
  --threshold 1.5 \
  --max-duration 180.0 \
  --keep-single-char
```

## ⚙️ 옵션 설명

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--threshold` | `1.0` | 병합 임계값(초) |
| `--max-duration` | `120.0` | 병합된 블록의 최대 시간(초) |
| `--keep-single-char` | `False` | 한 글자 자막 블록 유지 |

## 📊 효과 예시

### 병합 전
```srt
1
00:00:10,000 --> 00:00:11,500
안녕하세요

2
00:00:12,000 --> 00:00:14,000
반갑습니다
```

### 병합 후 (1초 임계값)
```srt
1
00:00:10,000 --> 00:00:14,000
안녕하세요
반갑습니다
```

## 📁 프로젝트 구조

```
srt_parser/
├── merge_srt.py          # 메인 스크립트
├── run_merge.sh          # 실행 스크립트
├── setup.sh              # 초기 설정 스크립트
├── requirements.txt      # Python 의존성
├── .gitignore           # Git 무시 파일
├── README.md            # 프로젝트 문서
├── venv/                # Python 가상환경
└── output/              # 결과 파일 저장 폴더
    └── *_stage.srt      # 병합된 자막 파일들
```

## 🔧 개발 환경

- **Python**: 3.7+
- **의존성**: 표준 라이브러리만 사용 (외부 패키지 불필요)

## 👨‍💻 작성자

**chanbyeong** - [chanbyeong@holamago.com](mailto:chanbyeong@holamago.com)

---

## 🔍 문제 해결

### 자주 발생하는 문제

**Q: "가상환경이 없습니다" 오류가 발생해요**
```bash
# 해결방법
python3 -m venv venv
source venv/bin/activate
```

**Q: 병합이 제대로 되지 않아요**
```bash
# 임계값을 늘려보세요
./run_merge.sh input.srt 2.0
```

**Q: 한 글자 자막을 유지하고 싶어요**
```bash
# 수동 실행으로 옵션 사용
python merge_srt.py input.srt output.srt --keep-single-char
```