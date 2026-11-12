from pathlib import Path
import plistlib

root = Path(__file__).resolve().parent.parent / "HermesEnabler2"
with (root / "MGOffsets.plist").open("rb") as f:
    offsets = plistlib.load(f)["Builds"]
with (root / "MGDefaults.plist").open("rb") as f:
    defaults = plistlib.load(f)["Builds"]

assert offsets.keys() == defaults.keys()
for build, entry in defaults.items():
    options = entry.get("UltraScreenClassOptions")
    if options is None:
        assert "UltraEnabledScreenClass" not in entry
        assert not offsets[build]["RecoveryVerified"]
        continue
    assert options in ([29], [29, 38])
    assert entry["UltraEnabledScreenClass"] in options
assert defaults["24S5112a"]["HermesEnabledDeviceBrand"] == 1
assert defaults["24S5112a"]["UltraEnabledScreenClass"] == 29
assert defaults["24S5112a"]["UltraScreenClassOptions"] == [29, 38]
assert offsets["24S5112a"]["CacheUUID"] == "830A9A56-15CC-4BB4-A1C3-F5F6FDB79819"
assert not offsets["24S5112a"]["RecoveryVerified"]
assert defaults["24S5284h"]["ModelValidation"]["Watch7,18"]["ExpectedOriginalScreenClass"] == 35
print("Ultra layout choices and unverified-build guard passed")
