#!/bin/bash

# Function to install downloaded dependencies and others in requiremnts.txt
install_deps() {
    echo "Installing downloaded Howso Python dependencies..."

    # Extract major.minor version from Python version
    python_major_minor="$(echo "${1}" | awk -F. '{print $1 "." $2}')"
    echo "Installing dependencies for Python $python_major_minor..."

    ./bin/build.sh install_deps $python_major_minor

    # Install custom Howso dependencies
    for repo in $(jq -r 'keys[]' "./env-repro/dependency-details.json"); do
        echo "Analyzing $repo for installable .whl files..."
        count=`ls -1 $repo/*.whl 2>/dev/null | wc -l`
        ls $repo
        if [[ $count != 0 && "$count" != "" ]]; then
            echo "Found custom $repo version; installing..."
            pip uninstall ${repo%-py} -y
            pip install $repo/*.whl --no-deps
        fi
        # Clean up leftover directory
        rm -rf $repo
    done

    pip list | grep amalgam || true
    pip list | grep howso || true
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
    for repo in $(jq -r 'keys[]' "./env-repro/dependency-details.json"); do
        echo "Downloading custom $repo..."
        run_type=$(jq -r --arg repo "$repo" '.[$repo]."run_type"')
        run_id=$(jq -r --arg repo "$repo" '.[$repo]."run_id"')
        plat=""
        arch=""
        if [[ "$repo" == "amalgam" && "$(basename $PWD)" == "amalgam-lang-py" ]]; then
            read -p "To reproduce the CI/CD environment, I must replace the Amalgam binaries in ./amalgam/lib/$plat/$arch. Proceed? (y/n): " proceed
            if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
                echo "No replacements made. Exiting."
                exit 1
            fi
            # Necessary since a-l-py tests will be run with an editable install of a-l-py
            echo "Downloading and extracting Amalgam binaries for $plat/$arch..."
            if [[ "$run_type" == "release" ]]; then
                gh $run_type download -D amalgam/lib/$plat/$arch -R "howsoai/$repo" -p "*${{ inputs.amalgam-plat-arch }}.tar.gz" "$run_id"
            else
                gh $run_type download -D amalgam/lib/$plat/$arch -R "howsoai/$repo" -p "*${{ inputs.amalgam-plat-arch }}" "$run_id"
            fi
            # Extract binaries
            cd amalgam/lib/$plat/$arch && if [ ! -f *.tar.gz ]; then mv */*.tar.gz ./; fi && tar -xvzf *.tar.gz
            cp lib/* .
            # Clean up downloaded directory
            rm *.tar.gz
            cd ../../../..
        elif [[ "$repo" == "howso-engine" && "$(basename $PWD)" == "howso-engine-py" ]]; then
            read -p "To reproduce the CI/CD environment, I must replace the Engine CAMLs in ./howso/howso-engine. Proceed? (y/n): " proceed
            if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
                echo "No replacements made. Exiting."
                exit 1
            fi
            # Necessary since hse-py tests will be run with an editable install of hse-py
            echo "Downloading and extracting Howso Engine CAMLs..."
            gh $run_type download -D howso/howso-engine -R "howsoai/$repo" -p "howso-engine-*" "$run_id"
            # Extract CAMLs
            cd howso/howso-engine && if [ ! -f *.tar.gz ]; then mv */*.tar.gz ./; fi && tar -xvzf *.tar.gz
            # Clean up downloaded directory
            rm *.tar.gz
            cd ../..
        elif [[ "$repo" != "amalgam" && "$repo" != "howso-engine" ]]; then
            gh $run_type download -D $repo -R "howsoai/$repo" -p "*-py3-none-any*" "$run_id"
            # Needed because release/non-release downloads are different structure
            cd $repo && if [ ! -f *.whl ]; then mv */*.whl ./; fi
            cd ..
            # Clean up downloaded directory
            rm -rf $repo
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
    read -p "Enter desired Python version (e.g., 3.13.1): " python_version
    
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
        pyenv install "$python_version"
    fi
    
    # Create the virtual environment
    pyenv virtualenv "$python_version" "$env_name"
    # Ensure user can do --user pip installs
    venv_path="$(pyenv root)/versions/$env_name"
    cfg_file="$venv_path/pyvenv.cfg"
    if [[ -f "$cfg_file" ]]; then
        sed -i '' -e 's/include-system-site-packages = .*/include-system-site-packages = true/' "$cfg_file"
        echo "Updated $cfg_file to allow --user pip installs."
        pyenv deactivate
        pyenv activate "$env_name"
        echo "Reactivated virtual environment."
    fi
    echo "Virtual environment '$env_name' created successfully. Setting local environment..."
    pyenv local $env_name
else
    # Create dependency directory
    dep_dir="howso-custom-deps"
    mkdir -p "$dep_dir"
    echo "Dependencies will be installed in '$dep_dir'."
fi

# Check for GitHub CLI installation and authentication
check_github_cli

download_artifacts

install_deps $python_version

echo "Success! Your virtual Python environment should now mirror that in which this script was generated."