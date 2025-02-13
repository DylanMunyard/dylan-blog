pipeline {
    agent any

    stages {
        stage('Build MkDocs') {
            steps {
                sh '''
                    #!/bin/bash
                    echo "Starting MkDocs build..."

                    # Install Python if not already available.  Consider using a tool like pyenv for more control.
                    # This example uses a basic installation. Adapt as needed for your OS.
                    if [ ! -f /usr/bin/python3 ]; then # Check for Python 3. If Python 2 is needed, adjust this.
                        echo "Installing Python 3..."
                        sudo apt-get update  # Update package lists (for Debian/Ubuntu based systems)
                        sudo apt-get install -y python3 python3-pip  # Install Python 3 and pip
                    fi

                    python3 -m pip install --upgrade pip
                    pip3 install -r requirements.txt

                    # Build the MkDocs site
                    mkdocs build

                    # Create an archive of the site (optional but recommended)
                    tar -czvf site.tar.gz site

                    echo "MkDocs build complete."
                '''
            }
        }

        stage('Publish MkDocs Site (Example: GitHub Pages)') {
            steps {
                sh '''
                    #!/bin/bash

                    echo "Publishing MkDocs site..."

                    # Example using mike deploy for GitHub Pages.  Adapt for your deployment method.
                    # You may need to install mike:  pip3 install mike

                    # Make sure mike is installed
                     if ! command -v mike &> /dev/null
                        then
                            pip3 install mike
                     fi

                    mike deploy --message "Jenkins build: ${BUILD_NUMBER}"

                    echo "MkDocs site published."
                '''
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'site.tar.gz, site/**' // Archive the built site and the tarball
            }
        }
    }
}