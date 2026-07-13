EX716 DiskOS image tool version 0.5.0

Verification:
  ./ex716disk.py --version
Expected:
  ex716disk.py 0.5.0

SHA-256:
  7c5b01a7e9fb5332ff2f605f79d4196a12dab0fb66478e226d51580abbd032c1

This build was regression-tested for:
  - FLAG_DELETED overriding FLAG_INUSE in normal directory listings
  - export File1 DISK00.disk argument ordering
  - import FileNew DISK00.disk argument ordering
