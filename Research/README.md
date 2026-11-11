# Research notes

These notes document the investigation behind HermesEnabler2 as of **2026-11-12**, based on the repository at commit `78188c74d284949deb4004a96efa84eb1a7017a2` and the locally preserved physical-device watchOS OTA material. They describe observed behavior and the implementation at that point; they are not Apple documentation.

- [MobileGestalt cache layout and offsets](MobileGestalt/README.md) — why the app uses different write paths, cache layout, and build-specific values.
- [Recovery and backups](Recovery/README.md) — how recovery candidates are derived, how backups are used, and what remains unverified.
- [Physical OTA research and reproduction](OTA/README.md) — source material, integrity checks, artifact provenance, and a repeatable analysis workflow.
- [Watch face availability](WatchFaces/README.md) — the Hermès and Ultra face investigation and its unresolved questions.

The OTA files and generated analysis reports are not part of this repository. Paths in the OTA note describe the original research machine and must be replaced on another machine. Never publish a device's MobileGestalt backup, region, serial number, or other device-specific data as part of a research report.

Related public projects are [Gester](https://github.com/sasobhabha/Gester), whose code is credited by this repository, [worse_query](https://github.com/forcequitOS/worse_query), a related sandbox-escape research project, and [ipsw](https://github.com/blacktop/ipsw), the OTA analysis tool used here. Their documentation provides context for those projects; the watchOS findings in these notes come from this repository and the recorded OTA analysis, not from assuming iOS behavior also applies to watchOS.

**Evidence labels used in these notes:** “code” means current app behavior; “static analysis” means a conclusion from a physical OTA binary or device-tree template; “runtime observation” describes a stated experiment and its scope. A template, a successful build, or a matching cache UUID alone does not establish that a feature or recovery works on a particular physical watch.
