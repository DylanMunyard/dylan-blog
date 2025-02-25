pipeline {
  agent {
    kubernetes {
      yamlFile 'deploy/pod.yaml'
    }
  }
  stages {
    stage('Docker build') {
      steps {
        container('dind') {
            sh '''
                docker build -f deploy/Dockerfile . -t container-registry-service.container-registry:5000/dylan-blog:latest
                docker push container-registry-service.container-registry:5000/dylan-blog:latest
            '''
        }
      }
    }
    stage('Deploy') {
      steps {
        container('kubectl') {
            withKubeConfig([namespace: "blog"]) {
              sh 'kubectl rollout restart deployment/blog'
            }
          }
        }
    }
  }
}