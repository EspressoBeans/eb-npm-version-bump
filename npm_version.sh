#!/bin/bash

#
echo --SET CLI PARAMETER DEFAULTS--
# ARGUMENTS
NPM_USER=myuser                            # REQUIRED IF USING -P SWITCH
NPM_PASSWORD=mypassword                    # REQUIRED IF USING -P SWITCH
NPM_EMAIL=vic.guadalupe@org.com            # REQUIRED IF USING -P SWITCH
NPM_PACKAGE=@my_org/my-app                 # REQUIRED
NPM_TAG=latest
NPM_PRIVATE=false

# ARGUMENTS FOR DEVELOPMENT TESTING
DEVELOPMENT=false
LOCAL_PATH='/mnt/c/Users/vic.guadalupe/SourceCode/my-app'  # REQUIRED IF USING -d SWITCH

# INTERNAL CONSTANTS
QA_PATH='C:\\Program Files (x86)\\Jenkins\\workspace\\AppBuild-QA\\SourceCode'     # A DEFAULT PATH TO THE APP'S QA SOURCE
TEST_PATH='C:\\Program Files (x86)\\Jenkins\\workspace\\AppBuild-TEST\\SourceCode' # A DEFAULT PATH TO THE APP'S TEST SOURCE
PROD_PATH='C:\\Program Files (x86)\\Jenkins\\workspace\\AppBuild-PROD\\SourceCode' # A DEFAULT PATH TO THE APP'S PROAD SOURCE

# INTERNALLY EVALUATED VARIABLES
NPM_PACKAGE_PATH=
ALPHA_TAG=alpha
BETA_TAG=beta
MAJOR=false
MINOR=false
PATCH=

# 
echo --SET INTERNAL PARAMETERS BASED ON ARGUMENTS
# LOOP THRU THE ARGUMENTS PASSED IN

for arg in $@
do
    case "$arg" in
        --user=*)     NPM_USER=${arg#*=}           ;;
        --password=*) NPM_PASSWORD=${arg#*=}       ;;
        --email=*)    NPM_EMAIL=${arg#*=}          ;;
        --package=*)  NPM_PACKAGE=${arg#*=}        ;;
        --tag=*)      NPM_TAG=${arg#*=}            ;;   
        --path=*)     LOCAL_PATH="${arg#*=}"       ;;
        -d)           DEVELOPMENT=true             ;;   
        -M)           MAJOR=true                   ;;      
        -m)           MINOR=true                   ;;   
        -P)           NPM_PRIVATE=true             ;;
        --help) 
            echo './npm_version.sh 
                --package  : REQUIRED, the package name (including scope if required),  (ex: --package="@my_org/my-app")        
                --user     : the npm registry account user                              (ex: --user="james")
                --password : the password associated with the npm registry account      (ex: --password="mypassword")
                --email    : the email associated with the npm registry account         (ex: --email="email@yahoo.com")
                --tag      : the desired dist-tag to publish with (latest, alpha, beta) (ex: --tag="alpha") (latest is default)
                --path     : when using the -d switch, pass the path to a package.json file 
                             > \''/mnt/c/Users/vic.guadalupe/SourceCode/has space/myapp\''
                             > \''C:\\Program Files (x86)\\Jenkins\\workspace\\RFQAppBuild-PROD\\SourceCode\''
                -d         : to denote running this script in a development mode
                [-M | -m]  : M = major, m = minor, this will bump version by a patch number unless -M or -m is specified
                -P         : for logging into private npm repository (this requires npm-cli-login package), also
                             the --user, --password, --email parameters are required for this.

                Note that you have to use the parameter name, then the equals sign, then the argument in quotes: --parm="argument"

                --path     REQUIRED if using -d switch
                --user     REQUIRED if using -P switch
                --password REQUIRED if using -P switch
                --email    REQUIRED if using -P switch

                Vic Guadalupe
            '
            exit 0 
            ;;
        *)
            echo "Unknown argument: $arg"
            exit 1
            ;;
     esac
done

# CREATE npm_publish_version.txt 
echo --CREATE npm_publish_version.txt FILE FOR USE WITH INJECTING JENKINS VARIABLES
rm npm_publish_version.txt
touch npm_publish_version.txt

# BASED ON PASSED TAG, SET NPM_PACKAGE_PATH
echo --SETTING NPM_PACKAGE_PATH BASED ON PASSED TAG
case $NPM_TAG in

  latest | "")
    NPM_PACKAGE_PATH=${PROD_PATH}
    ;;
  alpha)
    NPM_PACKAGE_PATH=${QA_PATH}
    ;;
  beta)
    NPM_PACKAGE_PATH=${TEST_PATH}
    ;;
  *)
    echo -n "--URECOGNIZED TAG: ${NPM_TAG}" 
    exit -1
    ;;
esac

# IF USING DEVELOPMENT FLAG, THEN USE THE LOCAL PATH VARIABLE
if [ $DEVELOPMENT == true ]; then
    NPM_PACKAGE_PATH=${LOCAL_PATH}
fi;

echo '>>' NPM_PACKAGE_PATH: ${NPM_PACKAGE_PATH}
NPM_PACKAGE_VERSION=$(node -p "require('${NPM_PACKAGE_PATH}/package.json').version") #PULLS PACKAGE.JSON VERSION

# IF EITHER THE MAJOR OR MINOR SWITCH IS PASSED, SET PATCH TO TRUE
if [[ $MAJOR == true || $MINOR == true ]]; then
    PATCH=false
else
    PATCH=true
fi;

#
if [[ $NPM_PRIVATE == true ]]; then
echo --LOGIN TO NPM PRIVATE REPO--
    npm-cli-login -u ${NPM_USER} -p ${NPM_PASSWORD} -e ${NPM_EMAIL}
fi

#
echo --PULL VERSIONS OF PACKAGE--
# THIS SHOWS ALL EXISTING DIST-TAGS LINE BY LINE
#npm dist-tag ls  

# THIS PULLS VERSIONS ONE BY ONE
VERSION_LATEST_FULL=`npm show ${NPM_PACKAGE} version`
VERSION_ALPHA_FULL=`npm show ${NPM_PACKAGE}@${ALPHA_TAG} version`
VERSION_BETA_FULL=`npm show ${NPM_PACKAGE}@${BETA_TAG} version`

echo '>>' VERSION_LATEST_FULL: ${VERSION_LATEST_FULL}
echo '>>' VERSION_ALPHA_FULL: ${VERSION_ALPHA_FULL}
echo '>>' VERSION_BETA_FULL: ${VERSION_BETA_FULL}

VERSION_LATEST_PATCH=${VERSION_LATEST_FULL##*.}
# IF THE FULL VERSION STRING CONTAINS THE PRERELEASE STRING, THEN PARSE THE LAST BUILD NUMBER, ELSE RETURN NOTHING
VERSION_ALPHA_BUILD=$([[ $VERSION_ALPHA_FULL = *$ALPHA_TAG* ]] && echo "${VERSION_ALPHA_FULL##*.}" || echo "")
VERSION_BETA_BUILD=$([[ $VERSION_BETA_FULL = *$BETA_TAG* ]] && echo "${VERSION_BETA_FULL##*.}" || echo "")

# echo  CURRENT LATEST: ${VERSION_LATEST_PATCH}
# echo  CURRENT ALPHA: ${VERSION_ALPHA_BUILD}
# echo  CURRENT BETA: ${VERSION_BETA_BUILD}


# THIS FUNCTION OUTPUTS THE SEMVER SECTIONS IN ORDER: _MAJOR, _MINOR, _PATCH, _SPECIAL
function semverParse() {
    local RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'
    #MAJOR
    eval $2=`echo $1 | sed -e "s#$RE#\1#"`
    #MINOR
    eval $3=`echo $1 | sed -e "s#$RE#\2#"`
    #MINOR
    eval $4=`echo $1 | sed -e "s#$RE#\3#"`
    #SPECIAL
    eval $5=`echo $1 | sed -e "s#$RE#\4#"`
}


#
# THIS IS FOR PRODUCTION, NO TAG PASSED, SO IT WILL DEFAULT TO LATEST IN NPM REGISTRY
if [[ -z "$NPM_TAG" || "$NPM_TAG" = "latest" ]]
then
    semverParse "$VERSION_LATEST_FULL" _MAJOR _MINOR _PATCH _SPECIAL

    if $MAJOR; then
        _MAJOR=$((_MAJOR + 1));
        _MINOR="0";
        _PATCH="0";
    elif $MINOR; then
        _MINOR=$((_MINOR + 1));
        _PATCH="0";
    elif $PATCH; then
        _PATCH=$((_PATCH + 1));
    fi

    PUBLISH_VERSION="$_MAJOR.$_MINOR.$_PATCH$_SPECIAL";
fi


#
# EVALUATE THE ALPHA IF IT IS WHAT WE ARE BUILDING
if [[ $NPM_TAG == $ALPHA_TAG ]] 
then
echo --EXECUTING ALPHA VERSION PROCESS--

    #CHECK IF WE ACTUALLY HAVE AN ALPH DIST-TAG IN NPM REGISTRY
    if [ -z "$VERSION_ALPHA_BUILD" ]
    then
        echo --ALPHA DIST-TAG DOES NOT EXIST
        VERSION_ALPHA_BUILD=0
    else
        echo --ALPHA DIST-TAG EXISTS
        # LETS USE THE EXISTING BUILD NUMBER AND INCREMENT IT
        VERSION_ALPHA_BUILD="$(($VERSION_ALPHA_BUILD + 1))"
    fi

    # PUT IT ALL TOGETHER
    PUBLISH_VERSION=${VERSION_LATEST_FULL}-${ALPHA_TAG}.${VERSION_ALPHA_BUILD}
    echo --NEW VERSION TO PUBLISH: ${PUBLISH_VERSION}
fi

# EVALUATE THE BETA IF IT IS WHAT WE ARE BUILDING
if [[ $NPM_TAG == $BETA_TAG ]] 
then
echo --EXECUTING BETA VERSION PROCESS--

    # CHECK IF WE ACTUALLY HAVE AN BETA DIST-TAG IN NPM REGISTRY
    if [ -z "$VERSION_BETA_BUILD" ]
    then
        echo --BETA DIST-TAG DOES NOT EXIST
        VERSION_BETA_BUILD=0
    else
        echo --BETA DIST-TAG EXISTS
        # LETS USE THE EXISTING BUILD NUMBER AND INCREMENT IT
        VERSION_BETA_BUILD="$(($VERSION_BETA_BUILD + 1))"
    fi

    # PUT IT ALL TOGETHER
    PUBLISH_VERSION=${VERSION_LATEST_FULL}-${BETA_TAG}.${VERSION_BETA_BUILD}
    echo --NEW VERSION TO PUBLISH: ${PUBLISH_VERSION}
fi

#
# OUTPUT VERSION AND PUBLISH SCRIPT
# IF NO TAG WAS PASSED, USE THE latest TAG FOR A PRODUCTION PUBLISH
VAR_TAG=$([ -z "$NPM_TAG" ] && echo "latest" || echo $NPM_TAG)
PUBLISH_SCRIPT="npm publish --tag "${VAR_TAG}

#
echo --WRITE TO FILE--
echo '>>' PUBLISH VERSION: ${PUBLISH_VERSION}
echo '>>' PUBLISH SCRIPT: ${PUBLISH_SCRIPT}
echo '>>' PACKAGE PATH: ${NPM_PACKAGE_PATH}
echo "PUBLISH_VERSION=${PUBLISH_VERSION}" >> npm_publish_version.txt
echo "PUBLISH_SCRIPT=${PUBLISH_SCRIPT}" >> npm_publish_version.txt
echo "PACKAGE_PATH=${NPM_PACKAGE_PATH}" >> npm_publish_version.txt

