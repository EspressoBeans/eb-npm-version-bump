# NPM Version Bump Script

  

#### Description

  

This is a bash script utility for publishing npm packages with correct versions. I use this for a Jenkins CI/CD build events of npm packages but can be adapted for whatever.

  

It pulls the current versions from npm registry then produces an output file with new version to use for publishing and npm publish script.

  

It currently accounts only for `latest`, `alpha`, and `beta`  `dist-tags`.

  

```
	--user     : the npm registry account user                              (ex: --user="james")
	--password : the password associated with the npm registry account      (ex: --password="mypassword")
	--email    : the email associated with the npm registry account         (ex: --email="email@yahoo.com")
	--package  : the package name (including scope if neccessary),          (ex: --package="@my_org/my-app")
	--path     : the path where to find the package.json of the package     (ex: --path="./SourceCode/react-app")
	--tag      : the desired dist-tag to publish with (latest, alpha, beta) (ex: --tag="alpha")
	[-P]       : this denotes a private repository. this will require the use of npm login credentials (user, password, email)
	[-M | -m]  : M = major, m = minor, this will bump version by a patch number unless -M or -m is specified

Note that you have to use the parameter name, then the equals sign, then the argument in quotes: --parm="argument"
The M | m is a switch that does not require an argument string

Vic Guadalupe

```

  

The output file produced is named **npm_publish_version.txt** and will include the following text:

```
PUBLISH_VERSION=[version output, example: 1.1.45-alpha.3]
PUBLISH_SCRIPT=[publish command, example: npm publish --tag latest]
```
  

The output can be used as key-value pairs for environment variable injection into CI/CD pipeline.
The **run.sh** script is a sample script which calls the **npm_version.sh** script

  

#### Debugging in Windows

In order to debug this script in VS Code in Windows, you need to have WSL (Windows Subsystem Linux) installed.  This is because the script uses the running *NIX instance to run the shell script.

  

1. [Docs on installing WSL on Windows 10:](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

2. [Install Ubuntu 18.04 LTS](https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q?rtc=1&activetab=pivot:overviewtab)
  
3. [Initialize Ubuntu on Windows 10](https://docs.microsoft.com/en-us/windows/wsl/initialize-distro)

4. [Install and configure Bash Debug extension in VS Code](https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug)


#### TODO

- Need to be able to commit new version in git repo when there is descrepancy between npm version and package.json version.
- Explain how to debug this with VS Code in Windows (using WSL)
- Update how paths are read into application as an argument (a path with spaces causes issues)
