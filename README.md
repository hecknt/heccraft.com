# heccraft.com
This is the repository for my website hosted over at https://heccraft.com

## Build

### Build Requirements
In order to build this site you need the following:
* [Pandoc](https://pandoc.org/)
* [GNU Make](https://www.gnu.org/software/make/)
* [GNU Core Utils](https://www.gnu.org/software/coreutils/)

### Build Instructions
First things first, you're gonna need to edit the `config` file inside of this repository. You will need to change the line that says `BLOG_REMOTE:=/var/www/main-site` to whatever directory you want the finished site to be in.

Run the following command inside the repository folder to build the site:
```sh
$ make build
```

and the following command to deploy the site into the BLOG_REMOTE folder:
```sh
$ make deploy
```
