# Additional MobileGestalt key recovery

This record describes the physical-device OTA descriptor analysis used to compare raw cache slots when restoring Boolean capability overrides. The physical OTA archives are kept separately from the repository.

## Method and limits

For `24R364`, `24R365`, `24S118`, `24S132`, `24S5112a`, and `24S5284h`, extract `libMobileGestalt.dylib` from a physical-device OTA dyld shared cache, apply slide fixups, locate the encrypted key string and its descriptor, and read the descriptor's stored index and type. Validate the relevant `CacheUUID`, data length, presence base, and offsets against the actual cache before any write. An index is not a device-specific default value.

The `AdditionalIndexes` entries in `MGOffsets.plist` list only stored descriptors observed in the extracted binaries. A stored descriptor's raw eight-byte slot and presence marker must match the initial backup before a different current cache may be accepted for `CacheExtra` restoration. The implementation only uses this per-slot comparison when `RecoveryVerified` is true. `24S5112a` descriptor indexes were observed in the physical OTA, but its `RecoveryVerified` remains false; `24R359` still lacks a matching independently analyzed physical OTA. Both therefore require the entire raw cache to match for this path.

| Setting / opaque key | 24R364 / 24R365 | 24S118 / 24S132 / 24S5112a / 24S5284h | Descriptor type |
| --- | ---: | ---: | ---: |
| Depth / `Ijs+pw5tRyxqSy5kfgZNuQ` | `0xa2` | `0xa3` | `11` |
| Absolute altimeter / `PFnuFyqMMnGUQQnTqS5byg` | `0xa1` | `0xa2` | `11` |
| Always-on compass / `aCQx2Qq/TChnNAq1rr6Egw` | `0xac` | `0xad` | `11` |
| Periodic ALS / `Leuy56dCZmAMYoVCQGTfPA` | `0x109` | `0x10a` | `11` |
| Raise to Speak / `4D8XW4YwJI7QvyPhv1TEdw` | `0x111` | `0x112` | `11` |
| Continuous heart rate / `W2RPjaqovtsgiRB6ScePGA` | `0xcc` | `0xcd` | `11` |
| Compass orienteering / `GPIs61LYNpcwZqwlFr7bbg` | `0xc9` | `0xca` | `11` |
| Battery information / `Kao6GNYdAy5hwXblxeGYJQ` | `0xb7` | `0xb8` | `11` |
| Always Listening / `U+73bmG4kBGj6kpreQXUTQ` | `0xaa` | `0xab` | `11` |
| Rotate to Wake / `nmOy2K5HzAAs2QNAi8wR+Q` | `0x282` | `0x283` | `11` |
| Apple Intelligence / `A62OafQ85EJAiiqKn4agtg` | `0xe4` | `0xe5` | `11` |
| On-Device Siri / `K/R1GfGfCkXvEhaPS2Vrng` | `0x123` | `0x124` | `5` |
| Audio Intelligence / `rb2tKZxlj0Gm2tBmUQSLqQ` | `0xb2` | `0xb3` | `11` |

The Swimming Workouts key `cRjPy4Ef+KZwJ+nfPeBV5Q` has index `0xffff` in the analyzed libraries. It has no ordinary stored slot and is deliberately absent from the table. The screen width and height descriptors are also unstored in the analyzed `24S118` library. Their cache-derived answers can depend on other inputs; a preset is not proof of a device's native dimensions.

Type `5` for the On-Device Siri descriptor must not be treated as evidence that its native value is a Boolean. The app only accepts an existing backup override of numeric 0 or 1 for the Boolean-toggle path; other values are rejected rather than coerced. The OTA descriptor observation does not validate every callback dependency, real-device access, or the original state of a particular watch.

## Recovery policy and unresolved snapshots

The initial backup is the first available source, followed by the existing system-derived recovery for the keys whose independent checks have been researched. A non-recoverable toggle restores the initial `CacheExtra` value, including the absence of an override, rather than forcing false. When a key's stored slot cannot be verified, a changed raw cache causes recovery to stop.

Other local snapshots are not yet selected automatically. A snapshot can contain an override from an earlier modification; an older timestamp, the same cache UUID, a non-enabled value, or agreement with other snapshots cannot by itself prove the device's original answer. The app must not present such a candidate as a verified factory value. Any future snapshot fallback needs a per-key independently verified device source or trustworthy provenance, and must refuse imported files and incomplete/mismatched snapshots by default.

`RegionCode` and sales-region values are per-device strings, not Boolean toggles; they have no independently validated fallback here. An initial backup taken after modification is not automatically original. An actual Ultra or Hermès watch can naturally have a value equal to an app activation value. Native fallback is constrained to the previously validated builds and checks; there has been no end-to-end physical-watch validation of these new paths.
