pipeline {
    agent { label 'python-agent' } 

    stages {
        stage('Build MkDocs') {
            steps {
                sh '''
                    pip install -r requirements.txt

                    # Build the MkDocs site
                    mkdocs build

                    echo "MkDocs build complete."
                '''
            }
            post {
                success {
                    archiveArtifacts 'site/**'
                }
            }
        }
    }
}