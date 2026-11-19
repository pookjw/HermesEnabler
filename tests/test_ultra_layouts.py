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
assert offsets["23U95"]["CacheUUID"] == "3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1"
assert offsets["23U95"]["CacheDataLength"] == 0x18a5
assert offsets["23U95"]["PresenceBase"] == 0x15e8
assert offsets["23U95"]["DeviceBrandOffset"] == 0x338
assert offsets["23U95"]["DeviceBrandPresentOffset"] == 0x164f
assert offsets["23U95"]["ScreenClassOffset"] == 0xe38
assert offsets["23U95"]["ScreenClassPresentOffset"] == 0x17af
assert not offsets["23U95"]["RecoveryVerified"]
assert defaults["23U95"]["UltraScreenClassOptions"] == [29, 38]
assert offsets["23U67"]["CacheUUID"] == "A4C66635-ED53-4978-87E5-943E7429FCF2"
for field in ("CacheDataLength", "PresenceBase", "DeviceBrandOffset", "DeviceBrandPresentOffset", "ScreenClassOffset", "ScreenClassPresentOffset", "Indexes"):
    assert offsets["23U67"][field] == offsets["23U95"][field]
assert not offsets["23U67"]["RecoveryVerified"]
assert defaults["23U67"]["UltraScreenClassOptions"] == [29, 38]
assert offsets["23R352"]["CacheUUID"] == "10ECA820-9649-4AB7-85B9-70D964798244"
assert offsets["23R352"]["CacheDataLength"] == 0x1842
assert offsets["23R352"]["PresenceBase"] == 0x1590
assert offsets["23R352"]["DeviceBrandOffset"] == 0x320
assert offsets["23R352"]["DeviceBrandPresentOffset"] == 0x15f4
assert offsets["23R352"]["ScreenClassOffset"] == 0xe00
assert offsets["23R352"]["ScreenClassPresentOffset"] == 0x1750
assert not offsets["23R352"]["RecoveryVerified"]
assert offsets["23R362"] == offsets["23R352"]
assert defaults["23R362"] == defaults["23R352"]
assert offsets["23S303"]["CacheUUID"] == "EB24BEC0-F912-41D5-8A19-5799312080EB"
assert offsets["23S303"]["CacheDataLength"] == 0x185d
assert offsets["23S303"]["PresenceBase"] == 0x15a8
assert offsets["23S303"]["DeviceBrandOffset"] == 0x328
assert offsets["23S303"]["ScreenClassOffset"] == 0xe10
assert not offsets["23S303"]["RecoveryVerified"]
assert offsets["23S314"]["CacheUUID"] == "0BAA3B39-6C56-4931-8F21-C4E629AA02DC"
for field in ("CacheDataLength", "PresenceBase", "DeviceBrandOffset", "DeviceBrandPresentOffset", "ScreenClassOffset", "ScreenClassPresentOffset", "Indexes"):
    assert offsets["23S314"][field] == offsets["23S303"][field]
assert not offsets["23S314"]["RecoveryVerified"]
assert offsets["23R350"] == offsets["23R352"]
assert offsets["23R8352"]["CacheUUID"] == "04C7248C-CCFC-41D2-BC0A-EDD2D1196890"
assert offsets["23R8352"] == offsets["23R8362"]
assert offsets["23S37"]["CacheUUID"] == "40ABD174-345A-4271-8315-8AD12A7B6689"
assert offsets["23S620"]["CacheUUID"] == "22983E80-2360-4F86-84D8-39258C19145B"
assert offsets["23T240"]["CacheUUID"] == "A38A2F0F-BA11-45AB-B42B-6A93FA8B8B71"
assert offsets["23T570"]["CacheUUID"] == "886404CC-479F-4F4B-B58C-870A08D6D22B"
for build in ("23R350", "23R352", "23R362", "23R8352", "23R8362", "23S37", "23S303", "23S314", "23S620", "23T240", "23T570", "23U67", "23U95"):
    layout = offsets[build]
    assert not layout["RecoveryVerified"]
    assert defaults[build]["UltraScreenClassOptions"] == [29, 38]
    for value, present in (("DeviceBrandOffset", "DeviceBrandPresentOffset"),
                           ("ScreenClassOffset", "ScreenClassPresentOffset")):
        assert layout[value] % 8 == 0
        assert layout[present] == layout["PresenceBase"] + layout[value] // 8
        assert layout[value] + 4 <= layout["CacheDataLength"]
        assert layout[present] < layout["CacheDataLength"]
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
assert offsets["24S5091f"]["CacheUUID"] == "982796A1-310A-4948-ACC0-6457C87BE79F"
assert offsets["24S5091f"]["CacheDataLength"] == 0x1950
assert offsets["24S5091f"]["DeviceBrandOffset"] == 0x348
assert offsets["24S5091f"]["DeviceBrandPresentOffset"] == 0x16e9
assert offsets["24S5091f"]["ScreenClassOffset"] == 0xeb0
assert offsets["24S5091f"]["ScreenClassPresentOffset"] == 0x1856
assert offsets["24S5091f"]["PresenceBase"] == 0x1680
assert not offsets["24S5091f"]["RecoveryVerified"]
assert offsets["24S5091f"]["Indexes"] == offsets["24S5086l"]["Indexes"]
assert offsets["24S5091f"]["AdditionalIndexes"] == offsets["24S5086l"]["AdditionalIndexes"]
assert defaults["24S5091f"]["MaxDeviceBrand"] == 2
assert defaults["24S5091f"]["HermesEnabledDeviceBrand"] == 1
assert defaults["24S5091f"]["UltraEnabledScreenClass"] == 29
assert defaults["24S5091f"]["UltraScreenClassOptions"] == [29, 38]
# Descriptor indexes were extracted from physical-device OTA libraries.
# The unstored swimming-workout descriptor (0xffff) must never become an offset.
for build in ("24R363", "24R364", "24R365", "24R5315i", "24S118", "24S132", "24S5086l", "24S5091f", "24S5112a", "24S5284h"):
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
