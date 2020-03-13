#!/bin/bash

#
echo --SET CLI PARAMETER DEFAULTS--
# ARGUMENTS
NPM_USER=
NPM_PASSWORD=
NPM_EMAIL=
NPM_PACKAGE=
NPM_PACKAGE_PATH=  #/mnt/c  EQUATES TO MOUNTED C DRIVE FOR WINDOWS USING WSL
NPM_TAG=latest

# INTERNALLY EVALUATED VARIABLES
NPM_PACKAGE_VERSION=$(node -p "require('${NPM_PACKAGE_PATH}/package.json').version") #PULLS PACKAGE.JSON VERSION
PRIVATE=false
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
        --path=*)     NPM_PACKAGE_PATH=${arg#*=}   ;;
        --tag=*)      NPM_TAG=${arg#*=}            ;;
        -P)           PRIVATE=true                  ;;
        -M)           MAJOR=true                   ;;      
        -m)           MINOR=true                   ;;   
        --help) 
            echo './npm_version.sh 
                --user     : the npm registry account user                              (ex: --user="james")
                --password : the password associated with the npm registry account      (ex: --password="mypassword")
                --email    : the email associated with the npm registry account         (ex: --email="email@yahoo.com")
                --package  : the package name (including scope),                        (ex: --package="@cranewwl_org/cranewwl-rfqapp")
                --path     : the path where to find the package.json of the package     (ex: --path="./SourceCode/react-app")
                --tag      : the desired dist-tag to publish with (latest, alpha, beta) (ex: --tag="alpha")
                [-P]       : this denotes a private repository.  this will cause the use of npm login credentials (user, password, email)
                [-M | -m]  : M = major, m = minor, this will bump version by a patch number unless -M or -m is specified

                Note that you have to use the parameter name, then the equals sign, then the argument in quotes: --parm="argument"
                The M | m is a switch that does not require an argument string

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



# IF EITHER THE MAJOR OR MINOR SWITCH IS PASSED, SET PATCH TO TRUE
if [[ $MAJOR == true || $MINOR == true ]]
then
    PATCH=false
else
    PATCH=true
fi;

#
# IF PRIVATE SWITCH WAS USED, THEN MAKE SURE THAT THE NPM USER/PASSWORD/EMAIL ARE PASSED IN
if [ $PRIVATE == true ] 
then
    # DO SOMETHING
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

echo  VERSION_LATEST_FULL: ${VERSION_LATEST_FULL}
echo  VERSION_ALPHA_FULL: ${VERSION_ALPHA_FULL}
echo  VERSION_BETA_FULL: ${VERSION_BETA_FULL}

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

    # CHECK THAT CURRENT PACKAGE.JSON VERSION IS FOR BETA PUBLISHING
    if [[ ! ${NPM_PACKAGE_VERSION} == *${ALPHA_TAG}* ]]
    then
        echo "THE package.json DOES NOT HAVE THE ${ALPHA_TAG} TAG"
        # WE NEED TO UPDATE THE package.json TO A NEW ALPHA RELEASE
        PUBLISH_VERSION=${VERSION_LATEST_FULL}-${ALPHA_TAG}.${VERSION_ALPHA_BUILD}
        echo NEW VERSION TO PUBLISH: ${PUBLISH_VERSION}
    fi
fi

# EVALUATE THE BETA IF IT IS WHAT WE ARE BUILDING
if [[ $NPM_TAG == $BETA_TAG ]] 
then
echo --EXECUTING BETA VERSION PROCESS--

    #CHECK IF WE ACTUALLY HAVE AN BETA DIST-TAG IN NPM REGISTRY
    if [ -z "$VERSION_BETA_BUILD" ]
    then
        echo --BETA DIST-TAG DOES NOT EXIST
        VERSION_BETA_BUILD=0
    else
        echo --BETA DIST-TAG EXISTS
        # LETS USE THE EXISTING BUILD NUMBER AND INCREMENT IT
        VERSION_BETA_BUILD= echo "$(($VERSION_BETA_BUILD + 1))"
    fi

    # CHECK THAT CURRENT PACKAGE.JSON VERSION IS FOR BETA PUBLISHING
    if [[ ! ${NPM_PACKAGE_VERSION} == *${BETA_TAG}* ]]
    then
        echo "THE package.json DOES NOT HAVE THE ${BETA_TAG} TAG"
        # WE NEED TO UPDATE THE package.json TO A NEW BETA RELEASE
        PUBLISH_VERSION=${VERSION_LATEST_FULL}-${BETA_TAG}.${VERSION_BETA_BUILD}
        echo NEW VERSION TO PUBLISH: ${PUBLISH_VERSION}
    fi
fi

#
# OUTPUT VERSION AND PUBLISH SCRIPT
# IF NO TAG WAS PASSED, USE THE latest TAG FOR A PRODUCTION PUBLISH
VAR_TAG=$([ -z "$NPM_TAG" ] && echo "latest" || echo $NPM_TAG)
PUBLISH_SCRIPT="npm publish --tag "${VAR_TAG}

#
echo --WRITE TO FILE--
echo PUBLISH VERSION: ${PUBLISH_VERSION}
echo PUBLISH SCRIPT: ${PUBLISH_SCRIPT}
rm npm_publish_version.txt
touch npm_publish_version.txt
echo "PUBLISH_VERSION=${PUBLISH_VERSION}" >> npm_publish_version.txt
echo "PUBLISH_SCRIPT=${PUBLISH_SCRIPT}" >> npm_publish_version.txt
