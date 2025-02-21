pipeline {
  agent {
    kubernetes {
      yamlFile 'docker/pod.yaml'
    }
  }
  stages {
    stage('Docker build') {
      steps {
        container('dind') {
            sh '''
                docker build -f docker/Dockerfile . -t container-registry-service.container-registry:5000/dylan-blog:latest
                docker push container-registry-service.container-registry:5000/dylan-blog:latest
            '''
        }
      }
    }
  }
}