pipeline {
    agent any

    stages {
        stage('Build MkDocs') {
            steps {
                sh '''
                    pip install -r requirements.txt

                    # Build the MkDocs site
                    mkdocs build

                    # Create an archive of the site (optional but recommended)
                    tar -czvf site.tar.gz site

                    echo "MkDocs build complete."
                '''
            }
        }
        post {
            success {
                archiveArtifacts 'site'
            }
        }
    }
}