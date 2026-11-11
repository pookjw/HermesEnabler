# HealthKit input probe

This standalone watchOS research app is based on the public-input probe contributed by [belcebu666 in PR #48](https://github.com/pookjw/HermesEnabler/pull/48). It is separate from the HermesEnabler app and does not enable Apple Readiness or compute a readiness score.

## What it does

- Requests only the public HealthKit read permissions selected by the user.
- Checks whether selected sample types are visible during the last 28 days and records availability and the number of days with samples. An empty query does **not** distinguish denied access from missing data; days with samples do not establish a complete baseline.
- With the `--validate-heartbeats` launch argument, examines at most 256 heartbeat series and reports counts, gap/error information, and whether RMSSD can be calculated as a finite number. It does not persist heartbeat times, RR intervals, or RMSSD values. The aggregate availability and coverage report is still potentially sensitive and should not be shared casually.
- With the `--inspect-schemas` launch argument, inspects private framework type schemas using discarded placeholders; it does not write those placeholders to HealthKit or pass them to a score calculation. This is research against private interfaces and can fail or change between builds.

Finite RMSSD is not proof of equivalence to Apple's Recovery HRV, and public inputs alone have not been shown to supply Apple's sleep-score, baseline, overnight/daytime summary, or training-load requirements. The PR reports that the original private queries returned HealthKit error 4 requiring `com.apple.private.healthkit`; this probe does not grant that entitlement or bypass that restriction. No fabricated score is displayed.

## Build and run

Open [HealthKitProbe.xcodeproj](HealthKitProbe.xcodeproj) in Xcode, choose your own signing team and a unique fixed bundle identifier, and enable HealthKit for that identifier. The included entitlement requests the public HealthKit capability; Apple's provisioning rules still apply. Run the separate target on a compatible watch, grant only the permissions you choose, and tap **Check Availability**. The probe saves availability summaries in its own Documents directory; it does not write HealthKit samples.

For an unsigned build check:

```sh
xcodebuild -project Research/HealthKitProbe/HealthKitProbe.xcodeproj \
  -scheme HealthKitProbe -configuration Debug -sdk watchos \
  -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
python3 Research/HealthKitProbe/test-rr.py
```

The synthetic RR test checks interval and gap handling. It does not test health permissions or validate an Apple score. The contributor reported running the original probe on a watch; this port has been built and tested with synthetic data, but has not been installed or run on a physical watch in this change.
