# Setting Up the EX716 Emulator Environment

The EX716 core is written in Python. It is recommended to use Python
3.10 or newer.

A few additional Python libraries are required. These are installed
using Python's package manager, pip.

The setup instructions below assume a Unix-like OS (Linux, WSL, or
macOS). Windows users may need minor adjustments.

------------------------------------------------------------------------------

Step-by-Step Setup Using venv

1. Choose a location and create a virtual environment:

    cd ~/projects   # or wherever you want to keep EX716
    python3 -m venv clean-ex716-env
    source clean-ex716-env/bin/activate

    You’ll know it worked when your shell prompt is prefixed with
    (clean-ex716-env).

2. Clone the EX716 Repository:

    git clone https://github.com/cosmofur/EX716
    cd EX716

3. Install Required Python Packages:

    pip install -r recommended.txt

    If recommended.txt is not present, you can create it manually
    with the known dependencies:

        numpy
        readchar
        rpdb

4. Set Required Environment Variables:

    You can run these manually or add them to your ~/.bashrc or ~/.zshrc:

        export PATH="$PATH:$(pwd):$(pwd)/lib"
        export CPUHOME="$(pwd)/lib"

    Make sure the lib/ subdiectory exists; if not, adjust the path accordingly.

5. Run the Emulator Test:

    cd tests
    python ../cpu.py -g

    This should bring you to the EX716 debugger prompt.

    Type 'q' followed by <enter> to exit.

You now should have a working version of cpu.py, which is the EX716
emulator, and are ready for lesson02.

