pipeline {
    agent any

    stages {
        stage('Build MkDocs') {
            steps {
                sh '''
                    #!/bin/bash
                    pip install -r requirements.txt

                    # Build the MkDocs site
                    mkdocs build

                    # Create an archive of the site (optional but recommended)
                    tar -czvf site.tar.gz site

                    echo "MkDocs build complete."
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