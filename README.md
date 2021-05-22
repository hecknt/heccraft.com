# heccraft.com
This is the repository for my website hosted over at https://heccraft.com

## Build

### Build Requirements
In order to build this site you need the following:
* [pandoc](https://github.com/jgm/pandoc)
* [ssg5](https://github.com/fmash16/ssg5)

### Build Instructions
Run the following commands inside the repository folder to build the site:
```sh
$ mkdir dst
$ ssg5 src dst "Hec's Website" "https://heccraft.com"
```
You will then have the site inside of the `dst` folder.
