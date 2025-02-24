#!/bin/bash

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
    echo "Virtual environment '$env_name' created successfully."
else
    # Create dependency directory
    dep_dir="howso-custom-deps"
    mkdir -p "$dep_dir"
    echo "Dependencies will be installed in '$dep_dir'."
fi

# Check for GitHub CLI installation and authentication
check_github_cli