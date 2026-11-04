#!/usr/bin/env bash
#
# 发版脚本
#
# 用法:
#   tool/release.sh <版本号> [发布说明]
#
# 例:
#   tool/release.sh 1.3.0 "补充统计分析页"
#
# 流程:
#   1. 校验工作区干净
#   2. 把 pubspec.yaml 的 version 改为指定版本
#   3. 构建 release APK
#   4. 提交版本号变更并打标签
#   5. 推送提交与标签
#   6. 创建 GitHub Release 并上传 APK
#
set -euo pipefail

VERSION="${1:-}"
NOTES="${2:-}"

if [ -z "$VERSION" ]; then
  echo "用法: tool/release.sh <版本号> [发布说明]"
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! git diff --quiet || [ -n "$(git status --porcelain)" ]; then
  echo "工作区不干净,请先提交或暂存改动:"
  git status --short
  exit 1
fi

if ! grep -q "^version:" pubspec.yaml; then
  echo "pubspec.yaml 中找不到 version 字段"
  exit 1
fi

echo "==> 更新版本号到 $VERSION"
python - "$VERSION" <<'PY'
import io, re, sys
v = sys.argv[1]
p = 'pubspec.yaml'
s = io.open(p, encoding='utf-8').read()
s2 = re.sub(r'^version:\s*.+$', 'version: %s' % v, s, count=1, flags=re.M)
io.open(p, 'w', encoding='utf-8', newline='').write(s2)
PY
grep -n "^version:" pubspec.yaml

echo "==> 构建 release APK"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
flutter build apk --release --no-tree-shake-icons

APK="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK" ]; then
  echo "未找到产物 $APK"
  exit 1
fi

mkdir -p dist
OUT="dist/双色球助手-v${VERSION}-release.apk"
cp "$APK" "$OUT"
echo "==> 产物: $OUT"

echo "==> 提交并打标签"
git add pubspec.yaml
git commit -m "release: v${VERSION}" -m "${NOTES}"
git tag -a "v${VERSION}" -m "双色球助手 v${VERSION}"
git push origin master
git push origin "v${VERSION}"

echo "==> 创建 GitHub Release"
if [ -n "$NOTES" ]; then
  gh release create "v${VERSION}" "$OUT" --title "双色球助手 v${VERSION}" --notes "$NOTES"
else
  gh release create "v${VERSION}" "$OUT" --title "双色球助手 v${VERSION}" --generate-notes
fi

echo "==> 完成:v${VERSION}"
