# TV Safari

Apple TV file browser and browser shell built in SwiftUI. Targets tvOS 13.0+ (project may use a higher deployment target). Will not work in a simulator for some features.

This project continues development from [Spartan](https://github.com/roto31/tvOS-Browser) (tvOS file browser by WhitetailAni and contributors).

Note that tvOS 13.x has a different user experience than 14.0+ due to SwiftUI limitations — it is still capable of the same operations, though.

What it currently lets you do:

- Browse file directory
- View and edit text files
- Watch videos (and view info)
- Play audio (and view metadata)
- Create folders
- Create files
- Create symlinks
- Save folders or files to Favorites
- Get info about a file
- Rename a file
- Move a file or files to Trash (or if in Trash, delete them)
- Move a file or files to a given directory (if a single file, you can rename it)
- Copy a file to a new filepath (and optionally, rename it)
- View images (and view info)
- View plist files (both xml and bplist)
- Spawn binaries (where the platform allows)
- Compress and uncompress .zip archives
- Search a directory and its subdirectories for a file or directory
- View all mounted devices
- Hex editor
- Font viewer
- Asset catalog name
- Display app icons/names/bundle IDs in container directories and /Applications
- Perform FS actions outside of /var/mobile (root helper where applicable)
- View HTML files
- Edit plist files

There's probably more — this list may be incomplete.

TV Safari now supports localization — please contribute to localizing it!

TODO:

- Fix tvOS 13 — waiting for my second TV HD to arrived.
- Fix asset catalog viewer
- SFTP server

It requires an Apple TV that is either jailbroken or has a kpf applied and is compatible with MDC to build and run, *currently*. Work is being done to add support for different schemes — jailbroken, jailed, etc.

How to use:

1. Clone the repository and open it in Xcode (15.0+ required).
2. Replace spawn.h in the tvOS SDK in Xcode.app with the spawn.h included in this repo.
3. [Install python2 if you don't have it natively](https://www.python.org/downloads/release/python-2718/?ref=blog.tericcabrel.com)
4. Build and run to your Apple TV.

Good luck have fun. Hopefully this isn't the only tvOS file browser ever.

[Donations if you want.](https://www.buymeacoffee.com/whitetailani)
