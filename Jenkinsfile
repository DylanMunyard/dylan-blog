pipeline {
  agent none
  parameters {
    booleanParam(name: 'BUILD_ALL', defaultValue: false, description: 'Build and deploy, ignoring changeset detection')
  }
  triggers {
    githubPush()
    pollSCM('H/5 * * * *')
  }
  stages {
    stage('Detect Changes') {
      agent {
        kubernetes {
          cloud 'Local k8s'
          namespace 'blog'
          yamlFile 'deploy/pod.yaml'
          nodeSelector 'kubernetes.io/hostname=bethany'
        }
      }
      steps {
        script {
          checkout scm

          def changedFiles = []
          for (int i = 0; i < currentBuild.changeSets.size(); i++) {
              def entries = currentBuild.changeSets[i].items
              for (int j = 0; j < entries.length; j++) {
                  changedFiles.addAll(entries[j].affectedPaths)
              }
          }

          if (!changedFiles) {
              echo "No changes detected via changeSets. Falling back to git diff."
              try {
                  def prevCommit = env.GIT_PREVIOUS_SUCCESSFUL_COMMIT ?: sh(script: 'git rev-parse HEAD~1', returnStdout: true).trim()
                  def changes = sh(script: "git diff --name-only ${prevCommit}..HEAD", returnStdout: true).trim()
                  changedFiles = changes ? changes.split('\n').toList() : []
              } catch (Exception e) {
                  echo "Error during git diff fallback: ${e.message}"
              }
          }

          if (changedFiles) {
              echo "Detected changed files: ${changedFiles.unique().join(', ')}"
          } else {
              echo "No changed files detected."
          }

          // Single-component app: the whole repo builds the static site.
          // Rebuild when any site source, the Dockerfile, or the k8s
          // manifest changes.
          env.BLOG_CHANGED = (changedFiles.any {
              it.startsWith('src/') ||
              it.startsWith('public/') ||
              it == 'astro.config.mjs' ||
              it == 'package.json' ||
              it == 'package-lock.json' ||
              it == 'tsconfig.json' ||
              it == 'deploy/Dockerfile' ||
              it.startsWith('deploy/k8s/blog-')
          }) ? 'true' : 'false'

          echo "BLOG_CHANGED=${env.BLOG_CHANGED}"
        }
      }
    }
    stage('Build and Deploy') {
      stages {
        stage('Build Blog Docker Image') {
          when { anyOf { expression { env.BLOG_CHANGED == 'true' }; expression { params.BUILD_ALL } } }
          agent {
            kubernetes {
              cloud 'Local k8s'
              namespace 'blog'
              yamlFile 'deploy/pod.yaml'
              nodeSelector 'kubernetes.io/hostname=bethany'
            }
          }
          steps {
            container('dind') {
              withCredentials([usernamePassword(credentialsId: 'dylanmunyard-dockerhub-pat', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh '''
                  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

                  docker buildx create --name multiarch-builder-blog --driver docker-container --use || true
                  docker buildx use multiarch-builder-blog

                  DOCKER_BUILDKIT=1 docker buildx build -f deploy/Dockerfile . \
                    --platform linux/amd64 \
                    --build-arg BUILDKIT_PROGRESS=plain \
                    --push \
                    -t dylanmunyard/dylan-blog:latest
                '''
              }
            }
          }
        }
        stage('Deploy Blog') {
          when { anyOf { expression { env.BLOG_CHANGED == 'true' }; expression { params.BUILD_ALL } } }
          agent {
            kubernetes {
              cloud 'Local k8s'
              namespace 'blog'
              yamlFile 'deploy/pod.yaml'
              nodeSelector 'kubernetes.io/hostname=bethany'
            }
          }
          steps {
            container('kubectl') {
              sh '''
                set -euo pipefail
                kubectl apply -f deploy/k8s/blog-deployment.yaml
                kubectl -n blog rollout restart deployment/blog
                kubectl -n blog rollout status deployment/blog --timeout=120s
              '''
            }
          }
        }
      }
    }
  }
}
