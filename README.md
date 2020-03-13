# eb-npm-version-bump

This is a bash script utility for publishing npm packages with correct versions.  I use this for a Jenkins CI/CD build events of npm packages but can be adapted for whatever.

It pulls the current versions from npm registry then produces an output file with new version to use for publishing and npm publish script.

It currently accounts only for `latest`, `alpha`, and `beta` `dist-tags`.

```
    --user     : the npm registry account user                              (ex: --user="james")
    --password : the password associated with the npm registry account      (ex: --password="mypassword")
    --email    : the email associated with the npm registry account         (ex: --email="email@yahoo.com")
    --package  : the package name (including scope if neccessary),                        (ex: --package="@cranewwl_org/cranewwl-rfqapp")
    --path     : the path where to find the package.json of the package     (ex: --path="./SourceCode/react-app")
    --tag      : the desired dist-tag to publish with (latest, alpha, beta) (ex: --tag="alpha")
    [-M | -m]  : M = major, m = minor, this will bump version by a patch number unless -M or -m is specified

    Note that you have to use the parameter name, then the equals sign, then the argument in quotes: --parm="argument"
    The M | m is a switch that does not require an argument string

    Vic Guadalupe, Crane Worldwide Logistics
```


**TODO**
- Currently only used for private repos, need to add flag that will bypass npm login when publishing public repos
- Need to be able to commit new version in git repo when there is descrepancy between npm version and package.json version.
