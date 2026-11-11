from pathlib import Path
import plistlib

root = Path(__file__).resolve().parent.parent / "HermesEnabler2"
with (root / "MGOffsets.plist").open("rb") as f:
    offsets = plistlib.load(f)["Builds"]
with (root / "MGDefaults.plist").open("rb") as f:
    defaults = plistlib.load(f)["Builds"]

assert offsets.keys() == defaults.keys()
for build, entry in defaults.items():
    options = entry["UltraScreenClassOptions"]
    assert options == ([29] if build == "24R359" else [29, 38])
    assert entry["UltraEnabledScreenClass"] in options
    assert (38 in options) == offsets[build]["RecoveryVerified"]
assert defaults["24S5284h"]["ModelValidation"]["Watch7,18"]["ExpectedOriginalScreenClass"] == 35
print("Ultra layout choices and unverified-build guard passed")
