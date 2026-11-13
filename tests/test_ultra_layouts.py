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
assert offsets["24R5315i"]["CacheUUID"] == "A4A7B9EC-7C2A-4E22-B1D2-179C9F27F6F1"
assert offsets["24R5315i"]["CacheDataLength"] == 0x1947
assert offsets["24R5315i"]["DeviceBrandOffset"] == 0x348
assert offsets["24R5315i"]["DeviceBrandPresentOffset"] == 0x16e1
assert offsets["24R5315i"]["ScreenClassOffset"] == 0xea8
assert offsets["24R5315i"]["ScreenClassPresentOffset"] == 0x184d
assert not offsets["24R5315i"]["RecoveryVerified"]
assert defaults["24R5315i"]["UltraScreenClassOptions"] == [29, 38]
assert offsets["24R363"]["CacheUUID"] == "6F8372B0-1583-4031-A4BC-A54A18B0DD5A"
assert offsets["24R363"]["CacheDataLength"] == 0x1947
assert offsets["24R363"]["DeviceBrandOffset"] == 0x348
assert offsets["24R363"]["DeviceBrandPresentOffset"] == 0x16e1
assert offsets["24R363"]["ScreenClassOffset"] == 0xea8
assert offsets["24R363"]["ScreenClassPresentOffset"] == 0x184d
assert offsets["24R363"]["PresenceBase"] == 0x1678
assert not offsets["24R363"]["RecoveryVerified"]
assert defaults["24R363"]["UltraScreenClassOptions"] == [29, 38]
assert defaults["24R363"]["MaxDeviceBrand"] == 2
assert offsets["24S5086l"]["CacheUUID"] == "E7D9878A-EC20-4CED-AFA4-5AA134AC5F20"
assert offsets["24S5086l"]["CacheDataLength"] == 0x1950
assert offsets["24S5086l"]["DeviceBrandOffset"] == 0x348
assert offsets["24S5086l"]["DeviceBrandPresentOffset"] == 0x16e9
assert offsets["24S5086l"]["ScreenClassOffset"] == 0xeb0
assert offsets["24S5086l"]["ScreenClassPresentOffset"] == 0x1856
assert offsets["24S5086l"]["PresenceBase"] == 0x1680
assert not offsets["24S5086l"]["RecoveryVerified"]
assert defaults["24S5086l"]["MaxDeviceBrand"] == 2
assert defaults["24S5086l"]["UltraScreenClassOptions"] == [29, 38]
# Descriptor indexes were extracted from physical-device OTA libraries.
# The unstored swimming-workout descriptor (0xffff) must never become an offset.
for build in ("24R363", "24R364", "24R365", "24R5315i", "24S118", "24S132", "24S5086l", "24S5112a", "24S5284h"):
    layout = offsets[build]
    additional = layout["AdditionalIndexes"]
    assert len(additional) == (11 if build == "24R5315i" else 13)
    assert "cRjPy4Ef+KZwJ+nfPeBV5Q" not in additional
    assert len(set(additional.values())) == len(additional)
    assert not set(additional.values()) & set(layout["Indexes"].values())
    for index in additional.values():
        assert index * 8 + 8 <= layout["CacheDataLength"]
        assert layout["PresenceBase"] + index < layout["CacheDataLength"]
assert "AdditionalIndexes" not in offsets["24R359"]
assert defaults["24S5284h"]["ModelValidation"]["Watch7,18"]["ExpectedOriginalScreenClass"] == 35
print("Ultra layout choices and unverified-build guard passed")
