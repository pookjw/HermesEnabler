# Series 11 compatibility research — help wanted

This work separates working face changes from unfinished Readiness research.
It does **not** enable a working Apple Readiness score on Series 11.

## Current status

| Area | Result | Remaining work |
| --- | --- | --- |
| Hermès plus Ultra display class | Modular Ultra and its red night mode were verified on Watch7,18 / 24S5284h | Test other models/builds with independently recovered layouts |
| Watch gallery previews | Newly exposed faces can remain black before adding | Identify the actual gallery rendering process and its device classification |
| Other Ultra faces | Restriction queries and installed bundle inventory are available | Verify each face in the gallery; unrestricted does not mean successfully added |
| Toy Story | No matching face bundle was found in the tested build | Investigate an actual older-bundle port; a model change cannot restore missing code/assets |
| Readiness executable | A local experimental port reached the real UI | UI access is not a functioning score |
| Public HealthKit inputs | Public sample queries and heartbeat-series inspection work with consent | Establish compatibility with the native input model |
| Apple scoring | Still unavailable | Private HealthKit service authorization and equivalent input summaries remain unresolved |

No Apple application binaries, firmware, personal sample reports, provisioning
profiles, credentials, or signing identities are included.

## Reproduce the public-input probe

Create a separate watchOS SwiftUI app target in Xcode with deployment target
watchOS 27.0 or later. Add the three files in `PublicInputProbe/` to that target;
`InputProbe.swift` supplies the only `@main` entry point. Enable the public
HealthKit capability and add `NSHealthShareUsageDescription` describing the
read-only availability check. Use your own bundle identifier and signing team.
Do not add these files to the HermesEnabler app target.

On the Watch, choose the read permissions yourself, then select **Comprobar
disponibilidad**. A successful empty query does not distinguish denied access
from absent samples. The report counts days containing samples by end date;
this is not a count of complete nights or proof of a valid baseline.

Launch arguments for development:

* `--validate-heartbeats`: examines up to 256 recent series over 28 days,
  resets interval accumulation at gaps/invalid intervals, and checks whether
  mathematical RMSSD is finite. Only counts, error codes and coverage are saved.
  No timestamps, RR intervals or RMSSD quantities leave the process.
* `--inspect-schemas`: loads system frameworks and inspects their Decodable
  types. Placeholder values are used only to discover keys/types and discarded.
  They never enter HealthKit or a scoring call. The included schema report
  contains type names and coding keys only.

Finite RMSSD does not establish equivalence to Apple's Recovery HRV, continuous
sampling, clinical validity, or readiness-score sufficiency. The probe never
writes HealthKit samples or a fabricated score.

## Native engine integration findings

`AppliedSensingFitness.ReadinessManager` has a compute entry point accepting a
`HealthBalance.ReadinessInputsQueryResult`. This suggests a possible adapter
boundary, but an adapter has not been implemented or validated.

The result includes characteristics, most-recent samples, overnight vitals,
daytime vitals, sleep scores, activity-day summaries, workout training loads,
and workout-effort relationships. Overnight summaries include baseline ranges
and baseline comparisons. `SleepHealth.SleepScoreDaySummary` includes both a
sleep-day summary and sleep-score metrics. See `readiness-schemas.json` for the
runtime inspection, including partial/failed decoding paths.

The original app's private queries reported HealthKit error 4 and a requirement
for `com.apple.private.healthkit`. Public user authorization does not grant that
entitlement to a development signature. Changing the displayed hardware model
does not by itself solve this authorization failure.

Useful contributions:

1. Identify an authorized source or a verified reconstruction of the sleep-score
   and overnight/daytime summary inputs, preserving actual missing-data states.
2. Recover the input conversion and baseline logic sufficiently to test
   equivalence; document units, night boundaries, gaps and provenance.
3. Build an isolated adapter test that invokes the native engine with real,
   consented inputs and reports availability before integrating into the UI.
4. Diagnose Watch gallery previews against a normal face as a control.
5. Add independently verified build/model layouts without weakening existing
   guards or assuming the Series 11 offsets apply elsewhere.

## Historical face change boundaries

The historical reference in `Series11UltraReference.m` is intentionally guarded by model Watch7,18, build 24S5284h,
cache UUID, blob length, presence byte, and expected original/current values.
It changes the cached main-screen class 35 to 38 and preserves the independent
Hermès brand field. It requires a verified original backup, saves a pre-change
snapshot, checks the written result and attempts rollback on mismatch.
This is experimental, build-specific behavior, not general compatibility.
The reference is not compiled or wired into the current app: upstream now has its
own Ultra implementation, which this PR preserves. The findings above describe
the earlier local experiment, not validation of the current upstream toggle.

Diagnostic launch flags: `--ultra-diagnostics`, `--compatibility-report`, and
`--snapshot-probe`. Diagnostics do not automatically enable Ultra. The snapshot
probe returned nil for both a control and Ultra faces, so it did not isolate the
black-preview cause.

Run `python3 Research/test-rr.py` on macOS with Xcode to check gap/invalid
interval handling against the actual accumulator source using synthetic inputs.

## Contributing

Open a PR against the research branch or discuss findings on the upstream PR.
Include model, OS build, framework UUID/hash where relevant, reproduction steps,
and expected/observed behavior. Use synthetic fixtures for tests. Do not attach
health measurements, device identifiers, full personal logs, credentials,
profiles, or Apple binaries. Distinguish observed behavior from a hypothesis.
Keep any independently designed readiness score explicitly separate from Apple's.
