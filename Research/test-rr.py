from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parent
source = (root / "PublicInputProbe/HeartbeatValidation.swift").read_text()
accumulator = source[source.index("struct RRAccumulator"):source.index("func validateHeartbeatInputs")]
checks = r"""
var a = RRAccumulator()
for t in [0.0, 1.0, 2.1, 3.1] { a.append(time: t, precededByGap: false) }
assert(a.differences == 2 && a.hasFiniteRMSSD)
var b = RRAccumulator()
b.append(time: 0, precededByGap: false)
b.append(time: 1, precededByGap: false)
b.append(time: 5, precededByGap: true)
b.append(time: 6, precededByGap: false)
assert(b.differences == 0 && !b.hasFiniteRMSSD)
b.append(time: 7.1, precededByGap: false)
assert(b.differences == 1 && b.hasFiniteRMSSD)
var c = RRAccumulator()
c.append(time: .nan, precededByGap: false)
c.append(time: 0, precededByGap: false)
c.append(time: 0, precededByGap: false)
assert(c.invalidIntervals == 2 && !c.hasFiniteRMSSD)
print("RR validity and gap checks passed with synthetic test inputs")
"""
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "RRChecks.swift"
    path.write_text("import Foundation\n" + accumulator + checks)
    subprocess.run(["xcrun", "swift", "-module-cache-path", str(Path(directory) / "ModuleCache"), str(path)], check=True)
