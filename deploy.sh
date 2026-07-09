#!/bin/bash
# ─────────────────────────────────────────────────────────────
# 이은미 원클릭 배포 스크립트
# 쓰는 법:  ./deploy.sh "무엇을 고쳤는지 한 줄"
#   예)     ./deploy.sh "공시 문턱 0.70으로 수정"
# 하는 일:  수정일시(한국+미국) 자동 갱신 → 깃 커밋 → 깃허브 푸시(자동 배포)
# ─────────────────────────────────────────────────────────────
set -e
cd "$(dirname "$0")"

MSG="${1:-문서 수정}"                       # 커밋 메시지(안 적으면 "문서 수정")
export XDG_CACHE_HOME=/tmp/ghcache          # gh/git 캐시 권한 우회

# 1) 수정일시를 '지금'으로 자동 갱신 (한국 KST + 미국 ET 둘 다)
python3 - <<PY
import re, subprocess
def now(tz): return subprocess.check_output(["date","+%H:%M"], env={"TZ":tz,"PATH":"/bin:/usr/bin"}).decode().strip()
def day():   return subprocess.check_output(["date","+%Y-%m-%d"], env={"TZ":"Asia/Seoul","PATH":"/bin:/usr/bin"}).decode().strip()
d, kst, et = day(), now("Asia/Seoul"), now("America/New_York")
s = open("index.html", encoding="utf-8").read()
# 배지 · meta · footer 세 곳의 날짜/시각을 통째로 교체
s = re.sub(r"🕒 최종 수정 \d{4}-\d{2}-\d{2} \d{2}:\d{2} KST · \d{2}:\d{2} ET",
           f"🕒 최종 수정 {d} {kst} KST · {et} ET", s)
s = re.sub(r"수정일시 <b>\d{4}-\d{2}-\d{2} \d{2}:\d{2} KST \(\d{2}:\d{2} ET\)</b>",
           f"수정일시 <b>{d} {kst} KST ({et} ET)</b>", s)
s = re.sub(r"(최종 수정 )\d{4}-\d{2}-\d{2} \d{2}:\d{2} KST · \d{2}:\d{2} ET",
           rf"\g<1>{d} {kst} KST · {et} ET", s)
open("index.html","w",encoding="utf-8").write(s)
print(f"🕒 수정일시 갱신: {d} {kst} KST · {et} ET")
PY

# 2) 변경 없으면 종료
if git diff --quiet index.html; then
  echo "⚠️  index.html에 바뀐 내용이 없어요. (저장했는지 확인)"
  exit 0
fi

# 3) 커밋 + 푸시(=자동 배포)
git add index.html
git commit -q -m "docs(index): $MSG"
git push origin main
echo "✅ 배포 완료! 1분쯤 뒤 새로고침(Cmd+Shift+R): https://minnieming.github.io/quantinue-strategist/"
