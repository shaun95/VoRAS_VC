#!/bin/sh
printf "\033]0;Installer\007"
clear
rm *.bat

# Function to create or activate a virtual environment
prepare_install() {
    if [ -d ".venv" ]; then
        echo "Venv found. This implies VoRAS has been already installed or this is a broken install"
        printf "Do you want to execute run-voras.sh? (Y/N): " >&2
        read -r r
        r=$(echo "$r" | tr '[:upper:]' '[:lower:]')
        if [ "$r" = "y" ]; then
            ./run-voras.sh && exit 1
        else
            echo "Ok! The installation will continue. Good luck!"
        fi
        . .venv/bin/activate
    else
        echo "Creating venv..."
        requirements_file="requirements.txt"
        echo "Checking if python exists"
        if command -v python3 > /dev/null 2>&1; then
            py=$(which python3)
            echo "Using python3"
        else
            if python --version | grep -q 3.; then
                py=$(which python)
                echo "Using python"
            else
                echo "Please install Python3 or 3.11 manually."
                exit 1
            fi
        fi

        $py -m venv .venv
        . .venv/bin/activate
        python -m ensurepip
        # Update pip within the virtual environment
        pip3 install --upgrade pip
        echo
        echo "Installing VoRAS dependencies..."
        python -m pip install -r requirements.txt
        python -m pip uninstall torch torchvision torchaudio -y
        python -m pip install torch==2.0.0 torchvision==0.15.1 torchaudio==2.0.1 --index-url https://download.pytorch.org/whl/cu117
        finish
    fi
}

# Function to finish installation (this should install missing dependencies)
finish() {
    # Check if required packages are installed and install them if not
    if [ -f "${requirements_file}" ]; then
        installed_packages=$(python -m pip freeze)
        while IFS= read -r package; do
            expr "${package}" : "^#.*" > /dev/null && continue
            package_name=$(echo "${package}" | sed 's/[<>=!].*//')
            if ! echo "${installed_packages}" | grep -q "${package_name}"; then
                echo "${package_name} not found. Attempting to install..."
                python -m pip install --upgrade "${package}"
            fi
        done < "${requirements_file}"
    else
        echo "${requirements_file} not found. Please ensure the requirements file with required packages exists."
        exit 1
    fi
    clear
    echo "VoRAS has been successfully downloaded. Run the file run-voras.sh to run the web interface!"
    exit 0
}

# Loop to the main menu
if [ "$(uname)" = "Darwin" ]; then
    if ! command -v brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        brew install python
        export PYTORCH_ENABLE_MPS_FALLBACK=1
        export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
    fi
elif [ "$(uname)" != "Linux" ]; then
    echo "Unsupported operating system. Are you using Windows...?"
    echo "If yes, use the batch (.bat) file instead of this one!"
    exit 1
fi

prepare_install