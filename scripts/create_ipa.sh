#!/bin/bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/create_ipa.sh [--bundle-id IDENTIFIER] [--output PATH]

Builds an unsigned iOS IPA containing the iPhone companion app and its embedded
Apple Watch app. Requires macOS, Xcode, and xcodebuild; no signing certificate
or provisioning profile is used.

Options:
  --bundle-id IDENTIFIER  iOS app bundle ID (watch ID becomes IDENTIFIER.watchkitapp)
  --output PATH           IPA output path (default: build/ipa/HermesEnabler.ipa)
  -h, --help              Show this help
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle_id="com.example.HermesEnabler"
output_path="$repo_root/build/ipa/HermesEnabler.ipa"

while (($#)); do
    case "$1" in
        --bundle-id)
            [[ $# -ge 2 ]] || { echo "Missing value for --bundle-id" >&2; exit 2; }
            bundle_id="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { echo "Missing value for --output" >&2; exit 2; }
            output_path="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script needs macOS and Xcode to compile iOS and watchOS apps." >&2
    echo "It does not need a signing certificate, provisioning profile, or Apple account." >&2
    exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild was not found. Install Xcode and select it with xcode-select." >&2
    exit 1
fi

if [[ ! "$bundle_id" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
    echo "Invalid bundle identifier: $bundle_id" >&2
    exit 2
fi

case "$output_path" in
    /*) ;;
    *) output_path="$repo_root/$output_path" ;;
esac

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/hermes-unsigned-ipa.XXXXXX")"
cleanup() {
    rm -rf "$temp_dir"
}
trap cleanup EXIT

derived_data="$temp_dir/DerivedData"
app_path="$derived_data/Build/Products/Release-iphoneos/HermesCompanion.app"
staging_path="$temp_dir/staging"

echo "Building iPhone app and embedded Watch app without code signing..."
xcodebuild \
    -project "$repo_root/HermesEnabler2.xcodeproj" \
    -scheme HermesCompanion \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$derived_data" \
    COMPANION_BUNDLE_IDENTIFIER="$bundle_id" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY='' \
    build

if [[ ! -d "$app_path" ]]; then
    echo "Build succeeded but the iPhone app was not found at: $app_path" >&2
    exit 1
fi

watch_app="$(find "$app_path/Watch" -maxdepth 1 -type d -name '*.app' -print -quit 2>/dev/null || true)"
if [[ -z "$watch_app" ]]; then
    echo "The built iPhone app does not contain an embedded Watch app." >&2
    echo "Expected a Watch/*.app bundle inside HermesCompanion.app." >&2
    exit 1
fi

if find "$app_path" -name embedded.mobileprovision -print -quit | grep -q .; then
    echo "A provisioning profile was embedded; refusing to label this IPA unsigned." >&2
    exit 1
fi

mkdir -p "$staging_path/Payload" "$(dirname "$output_path")"
ditto "$app_path" "$staging_path/Payload/HermesCompanion.app"
ditto -c -k --sequesterRsrc --keepParent "$staging_path/Payload" "$output_path"

echo "Created unsigned IPA: $output_path"
echo "Embedded Watch app: Payload/HermesCompanion.app/Watch/$(basename "$watch_app")"
echo "Bundle IDs: $bundle_id and $bundle_id.watchkitapp"
echo "Sign the iPhone app and embedded Watch app with your own certificate and profiles before installing."
