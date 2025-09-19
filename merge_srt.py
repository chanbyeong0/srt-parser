#!/usr/bin/env python3
"""
merge_srt.py — 인접 간격이 1초(기본값) 이하인 블록을 '타임스탬프만' 머지합니다.

규칙
- 첫 블록의 번호를 유지하고, 합쳐지는 뒤 블록은 삭제합니다(번호 재부여 안 함).
- 머지 후 시작 시간은 앞 블록의 시작, 종료 시간은 뒤 블록의 종료로 설정합니다.
- 텍스트는 줄바꿈을 유지하여 순서대로 이어 붙입니다(의미 변경 없음).
- 머지 기준: (다음.start - 현재.end) <= threshold(초) 이고 0 이상(겹침은 제외).
- 한 글자 자막 블록은 자동으로 제거됩니다 (--keep-single-char로 비활성화 가능).
- 병합된 블록의 전체 시간이 2분을 넘으면 병합을 중단하고 다음 블록부터 새로 시작합니다.

사용법
    python merge_srt.py input.srt output.srt --threshold 1.0 --max-duration 120.0
"""
import argparse
import re
from datetime import timedelta

TIME_RE = re.compile(r'(\d{2}):(\d{2}):(\d{2}),(\d{3})')
ARROW = '-->'

def parse_time(s: str) -> timedelta:
    m = TIME_RE.match(s.strip())
    if not m:
        raise ValueError(f"Invalid time format: {s!r}")
    hh, mm, ss, ms = map(int, m.groups())
    return timedelta(hours=hh, minutes=mm, seconds=ss, milliseconds=ms)

def format_time(td: timedelta) -> str:
    total_ms = int(td.total_seconds() * 1000)
    if total_ms < 0:
        total_ms = 0
    ms = total_ms % 1000
    total_s = total_ms // 1000
    s = total_s % 60
    total_m = total_s // 60
    m = total_m % 60
    h = total_m // 60
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

def parse_srt(text: str):
    # SRT 블록 분리
    raw_blocks = re.split(r'\n\s*\n', text.strip(), flags=re.MULTILINE)
    blocks = []
    for raw in raw_blocks:
        lines = [ln.rstrip('\r') for ln in raw.splitlines()]
        if not lines:
            continue
        # 첫 줄: 번호 (숫자)
        idx_line = lines[0].strip()
        if not idx_line.isdigit():
            index = None
            head = lines[0]
            body_lines = lines[1:]
        else:
            index = int(idx_line)
            head = lines[1] if len(lines) > 1 else ''
            body_lines = lines[2:] if len(lines) > 2 else []

        # 타임라인 파싱
        if ARROW not in head:
            search_pool = lines[1:4] if len(lines) > 1 else []
            for cand in search_pool:
                if ARROW in cand:
                    head = cand
                    start_at = lines.index(cand) + 1
                    body_lines = lines[start_at+1:]
                    break
        if ARROW not in head:
            raise ValueError(f"SRT timeline missing in block starting with: {lines[:3]}")

        start_str, end_str = [p.strip() for p in head.split(ARROW)]
        start = parse_time(start_str)
        end = parse_time(end_str)

        blocks.append({
            'index': index,
            'start': start,
            'end': end,
            'text': body_lines
        })
    return blocks

def dump_srt(blocks):
    out_lines = []
    for b in blocks:
        idx = '' if b['index'] is None else str(b['index'])
        out_lines.append(idx)
        out_lines.append(f"{format_time(b['start'])} {ARROW} {format_time(b['end'])}")
        if b['text']:
            out_lines.extend(b['text'])
        else:
            out_lines.append('')
        out_lines.append('')
    return '\n'.join(out_lines).rstrip() + '\n'

def filter_single_char_blocks(blocks):
    """
    한 글자만 있는 자막 블록을 제거합니다.
    """
    filtered_blocks = []
    for block in blocks:
        # 텍스트 라인들을 합쳐서 전체 텍스트 길이 확인
        full_text = ''.join(block['text']).strip()
        # 공백, 특수문자 제거 후 실제 글자 수 확인
        clean_text = ''.join(c for c in full_text if c.isalnum() or ord(c) > 127)  # 한글, 영문, 숫자만
        
        if len(clean_text) > 1:  # 2글자 이상인 경우만 유지
            filtered_blocks.append(block)
    
    return filtered_blocks

def merge_adjacent(blocks, threshold_sec: float, max_duration_sec: float = 120.0):
    """
    인접 블록 간 간격이 threshold_sec 이하면 머지합니다.
    간격 정의: gap = next.start - curr.end (초)
    조건: 0 <= gap <= threshold_sec
    추가 제한: 병합된 블록의 전체 시간이 max_duration_sec를 넘으면 병합 중단
    """
    i = 0
    while i < len(blocks) - 1:
        curr = blocks[i]
        nxt = blocks[i + 1]
        gap = (nxt['start'] - curr['end']).total_seconds()
        
        # 간격 조건 확인
        if 0 <= gap <= threshold_sec:
            # 병합 후 전체 시간 계산
            merged_duration = (nxt['end'] - curr['start']).total_seconds()
            
            # 최대 시간 제한 확인 (2분 = 120초)
            if merged_duration <= max_duration_sec:
                # 병합 실행
                curr['end'] = nxt['end']
                if curr['text'] and nxt['text']:
                    curr['text'] = curr['text'] + nxt['text']
                elif not curr['text'] and nxt['text']:
                    curr['text'] = nxt['text']
                del blocks[i + 1]
                # 같은 인덱스에서 계속 (다음 블록과도 병합 시도)
            else:
                # 2분을 넘으면 병합하지 않고 다음 블록으로 이동
                i += 1
        else:
            i += 1
    return blocks

def main():
    ap = argparse.ArgumentParser(description="SRT 타임스탬프 인접 병합 도구")
    ap.add_argument('input', help='입력 SRT 경로')
    ap.add_argument('output', help='출력 SRT 경로')
    ap.add_argument('--threshold', type=float, default=1.0,
                    help='머지 임계값(초). 기본 1.0')
    ap.add_argument('--max-duration', type=float, default=120.0,
                    help='병합된 블록의 최대 시간(초). 기본 120.0 (2분)')
    ap.add_argument('--keep-single-char', action='store_true',
                    help='한 글자 자막 블록을 유지 (기본: 삭제)')
    args = ap.parse_args()

    with open(args.input, 'r', encoding='utf-8') as f:
        text = f.read()

    blocks = parse_srt(text)
    
    # 한 글자 자막 필터링 (옵션으로 비활성화 가능)
    if not args.keep_single_char:
        original_count = len(blocks)
        blocks = filter_single_char_blocks(blocks)
        filtered_count = original_count - len(blocks)
        if filtered_count > 0:
            print(f"한 글자 자막 블록 {filtered_count}개를 제거했습니다.")
    
    merged = merge_adjacent(blocks, args.threshold, args.max_duration)
    out = dump_srt(merged)

    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(out)

if __name__ == '__main__':
    main()
