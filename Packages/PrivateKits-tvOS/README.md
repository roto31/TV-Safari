# PrivateKits-tvOS

Swift package used by **TV Safari**: thin wrappers and module maps around **tvOS system frameworks** and C headers (e.g. compression, disk images, asset catalogs, SVG) that are not exposed as stable Swift APIs.

- Targets **tvOS**; some headers were adjusted for the tvOS SDK vs. iOS-only samples.  
- See **`Package.swift`** for product names (`DiskImagesWrapper`, `FSOperations`, `AssetCatalogWrapper`, etc.).  
- Treat APIs as **private / unstable** — verify behavior on your tvOS version before relying on them in production.
