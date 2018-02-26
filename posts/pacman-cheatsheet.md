Title: Pacman cheatsheet
Category: Cheatsheets
Tags: pacman, archlinux
Date: 2018-02-25 18:55

| Task | Command | Notes |
|------|---------|-------|
| Update and upgrade all|pacman -Syu|Update and upgrade best done as package deal|
|Exclude bad signature package|	pacman -Syu --ignore badpkgname	|Do if pacman -S archlinux-keyring didn't work|
|Install specific package	|pacman -S pkgname	||
|Find available packages	|pacman -Ss keyword|	Like apt-cache search|
|Find available local packages|pacman -Qs keyword|Like -Ss but local only|
|List all files from package|	pacman -Ql |pkgname	|
|Find your distro version|	lsb_release -a	||