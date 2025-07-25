#!/bin/bash

# Whether to install custom deps or simply store them
# Set by user prompt
noinstall=false
# Directory to store custom steps if noinstall==1
dep_dir="howso-custom-deps"

# Function to install downloaded dependencies and others in requiremnts.txt
install_deps() {

    if [ $noinstall = true ]; then
        echo "Moving downloaded .whl files to $dep_dir"
    else
        echo "Installing downloaded Howso Python dependencies..."

        # Extract major.minor version from Python version
        python_major_minor="$(echo "${1}" | awk -F. '{print $1 "." $2}')"
        echo "Installing dependencies for Python $python_major_minor..."

        pip install --upgrade pip

        # Make a copy of build.sh that doesn't include a --user install
        cp bin/build.sh bin/build_nouser.sh && chmod +x bin/build_nouser.sh
        plat="$(uname -s | tr '[:upper:]' '[:lower:]')"
        if [[ "$plat" == "darwin" ]]; then
            sed -i '' "s|--user||g" bin/build_nouser.sh
        else
            sed -i "s|--user||g" bin/build_nouser.sh
        fi
        ./bin/build_nouser.sh install_deps $python_major_minor
        rm -f bin/build_nouser.sh
    fi

    # Install custom Howso dependencies
    for repo in $(jq -rc 'keys[]' <<< '{UPSTREAM_DETAILS}'); do
        echo "Analyzing $repo for installable .whl files..."
        count=`ls -1 $repo-whl/*.whl 2>/dev/null | wc -l`
        ls $repo-whl
        if [[ $count != 0 && "$count" != "" ]]; then
            if [ $noinstall = true ]; then
                echo "Found custom $repo version; transferring..."
                mv $repo/*.whl $dep_dir
            else
                echo "Found custom $repo version; installing..."
                pip uninstall ${repo%-py} -y
                pip install $repo-whl/*.whl --no-deps
            fi
        fi
        # Clean up leftover directory
        rm -rf $repo-whl
    done

    if [ $noinstall = true ]; then
        ls -l $dep_dir
    else
        pip list | grep amalgam || true
        pip list | grep howso || true
    fi
}

# Function to set appropriate environment variables
set_env_vars() {
    export TEST_OPTIONS=USE_HOWSO_CONFIG
    export HOWSO_CONFIG=${1}
    env | grep HOWSO_CONFIG
}

# Function to determine CPU architecture
detect_arch() {
    local arch="$(uname -m)"
    if [[ "$arch" == "x86_64" ]]; then
        echo "amd64"
    elif [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
        echo "arm64"
    else
        echo "Unsupported architecture: $arch" >&2
        exit 1
    fi
}

# Function to read a dependency details JSON and download Howso artifacts from GitHub
download_artifacts() {
    plat="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(detect_arch)"
    for repo in $(jq -rc 'keys[]' <<< '{UPSTREAM_DETAILS}'); do
        echo "Evaluating custom $repo..."
        run_type=$(jq -r --arg repo "$repo" '.[$repo]."run_type"' <<< '{UPSTREAM_DETAILS}')
        run_id=$(jq -r --arg repo "$repo" '.[$repo]."run_id"' <<< '{UPSTREAM_DETAILS}')
        echo "Got run_type=$run_type, run_id=$run_id"
        if [[ "$repo" == "amalgam" && "$(basename $PWD)" == "amalgam-lang-py" ]]; then
            read -p "To reproduce the CI/CD environment, I must replace the Amalgam binaries in ./amalgam/lib/$plat/$arch. Proceed? (y/n): " proceed
            if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
                echo "No replacements made. Exiting."
                exit 1
            fi
            # Necessary since a-l-py tests will be run with an editable install of a-l-py
            echo "Downloading and extracting Amalgam binaries for $plat/$arch..."
            if [[ "$run_type" == "release" ]]; then
                gh $run_type download -D amalgam/lib/$plat/$arch -R "howsoai/$repo" -p "*$plat-$arch.tar.gz" "$run_id"
            else
                gh $run_type download -D amalgam/lib/$plat/$arch -R "howsoai/$repo" -p "*$plat-$arch" "$run_id"
            fi
            # Extract binaries
            cd amalgam/lib/$plat/$arch && if [ ! -f *.tar.gz ]; then mv */*.tar.gz ./ && cd ../../..; fi && tar -xvzf *.tar.gz
            cp lib/* .
            # Clean up downloaded directory
            rm *.tar.gz
        elif [[ "$repo" == "howso-engine" && "$(basename $PWD)" == "howso-engine-py" ]]; then
            read -p "To reproduce the CI/CD environment, I must replace the Engine CAMLs in ./howso/howso-engine. Proceed? (y/n): " proceed
            if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
                echo "No replacements made. Exiting."
                exit 1
            fi
            # Remove any existing howso.caml
            rm -f howso/howso-engine/howso.caml
            # Necessary since hse-py tests will be run with an editable install of hse-py
            echo "Downloading and extracting Howso Engine CAMLs..."
            gh $run_type download -D howso/howso-engine -R "howsoai/$repo" -p "howso-engine-*" "$run_id"
            # Extract CAMLs
            cd howso/howso-engine && if [ ! -f *.tar.gz ]; then mv */*.tar.gz ./ && cd ../..; fi && tar -xvzf *.tar.gz
            # Clean up downloaded directory
            rm *.tar.gz
        elif [[ "$repo" != "amalgam" && "$repo" != "howso-engine" ]]; then
            echo "Downloading..."
            gh $run_type download -D $repo-whl -R "howsoai/$repo" -p "*-py3-none-any*" "$run_id"
            # Needed because release/non-release downloads are different structure
            cd $repo-whl && if [[ "$run_type" == "run" ]]; then mv */*.whl ./ && cd ..; fi
        fi
    done
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if GitHub CLI is installed and logged in
check_github_cli() {
    if command_exists gh; then
        echo "GitHub CLI is installed."
        if gh auth status &>/dev/null; then
            echo "GitHub CLI is logged in."
        else
            echo "GitHub CLI is installed but not logged in. Run 'gh auth login' to authenticate."
        fi
    else
        echo "GitHub CLI is not installed. Install it from https://cli.github.com/."
    fi
}

# First, make sure user is running this script from top level of repo
if [[ ! -e ./bin/build.sh ]]; then
    echo "File ./bin/build.sh not found; are you in repository root?"
    exit 2
fi

# Get user choice for virtual environment or dependency directory
read -p "Do you want to create a virtual environment? (y/n): " create_venv

if [[ "$create_venv" =~ ^[Yy]$ ]]; then
    python_version={PYTHON_VERSION}
    
    # Ensure pyenv and pyenv-virtualenv are installed
    if ! command_exists pyenv; then
        echo "pyenv is not installed. Install it from https://github.com/pyenv/pyenv."
        exit 1
    fi
    if ! pyenv commands | grep -q virtualenv; then
        echo "pyenv-virtualenv is not installed. Install it from https://github.com/pyenv/pyenv-virtualenv."
        exit 1
    fi
    
    # Generate environment name with current date
    env_name="howso-custom-env-$(date +%m-%d-%y)"
    
    # Check if the virtual environment already exists
    if pyenv virtualenvs | grep -q "$env_name"; then
        echo "Error: Virtual environment '$env_name' already exists."
        exit 1
    fi

    # Check if the requested Python version is installed, install only if necessary
    if ! pyenv versions | grep -q "$python_version"; then
        # Ensure the exact version is available
        if ! pyenv install --list | grep -q "$python_version"; then
            python_major_minor="$(echo "$python_version" | awk -F. '{print $1 "." $2}')"
            use_major_minor=true
            echo "WARNING: Exact Python version from GitHub ($python_version) not available to Pyenv. Using Pyenv's default minor version (${python_major_minor}.X)"
            if ! pyenv versions | grep -q "$python_major_minor"; then
                pyenv install $python_major_minor
            fi
            python_version=$python_major_minor
        else
            pyenv install "$python_version"
        fi
    fi
    
    # Create the virtual environment
    pyenv virtualenv "$python_version" "$env_name"
    echo "Virtual environment '$env_name' created successfully. Setting local environment..."
    pyenv local $env_name
else
    # Create dependency directory
    noinstall=true
    mkdir -p "$dep_dir"
    echo "Dependencies will be installed in '$dep_dir'."
fi

# Check for GitHub CLI installation and authentication
check_github_cli

download_artifacts

install_deps $python_version

set_env_vars {HOWSO_CONFIG_PATH}

if [ $noinstall = true ]; then
    echo -e "\n\nAll custom artifacts downloaded to $dep_dir. Please first `pip install` the appropriate `requirements.txt` file, then install the custom Howso packages manually with `--no-deps`."
else
    echo -e "\n\nSuccess! Your virtual Python environment should now mirror that in which this script was generated."
fi
