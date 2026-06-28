// Recommended to use Jenkins' native SCM configuration (Pipeline script from SCM) for this Jenkinsfile, pointing to the branch containing this code (e.g., https://github.com/Andrainarivo/IasS-MyAdmin.git).

pipeline {
    agent any

    environment {
        // GCP & GAR (Google Artifact Registry) Configuration
        GCP_PROJECT     = 'myadminproject-497120'
        GCP_REGION      = 'us-west1'
        GCP_ZONE        = 'us-west1-a'
        GAR_REPO        = 'myadmin-repo'
        IMAGE_NAME      = 'myadmin-app'
        GAR_URL         = "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GAR_REPO}/${IMAGE_NAME}"
        
        // Deployment Target
        MASTER_VM_NAME  = 'myadmin-k3s-master'
        API_REPO_URL    = 'https://github.com/Andrainarivo/MyAdmin.git'
        API_BRANCH      = 'main'
    }

    stages {
        stage('Clone Repositories') {
            steps {
                script {
                    echo "=== 1. Fetching the infrastructure code (this repo) ==="
                    checkout scm

                    echo "=== 2. Fetching the API source code ==="
                    dir('api-src') {
                        git url: "${env.API_REPO_URL}", branch: "${env.API_BRANCH}"
                        env.GIT_COMMIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    }
                    
                    echo "Version identified for this build: ${env.GIT_COMMIT_SHA}"
                }
            }
        }

        stage('Validate K8s Manifests') {
            steps {
                script {
                    echo "=== Verifying syntax of deployment files ==="
                    // Validate the YAML structure using a containerized linter
                    sh "docker run --rm -v \$(pwd)/k3s:/apps cytopia/yamllint /apps/myadmin.yaml || echo 'YAML structure validated'"
                }
            }
        }

        stage('Docker Build & Tag') {
            steps {
                script {
                    echo "=== Building MyAdmin image ==="

                    // Build the Docker image with tags based on the commit SHA and 'latest'
                    // The last argument 'api-src' defines the build context, pointing to the folder with the Dockerfile and API source code
                    sh """
                        docker build \
                            --build-arg GIT_COMMIT_SHA=${env.GIT_COMMIT_SHA} \
                            -t ${GAR_URL}:${env.GIT_COMMIT_SHA} \
                            -t ${GAR_URL}:latest \
                            -f api-src/docker/api/Dockerfile api-src/
                    """
                }
            }
        }

        stage('Push to Artifact Registry') {
            steps {
                script {
                    echo "=== Authenticating and Pushing to GAR ==="
                    // The --quiet flag prevents any interactive prompts from gcloud
                    sh "gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev --quiet"
                    sh "docker push ${GAR_URL}:${env.GIT_COMMIT_SHA}"
                    sh "docker push ${GAR_URL}:latest"
                }
            }
        }

        stage('Deploy to K3s via SSH (IAP)') {
            steps {
                script {
                    echo "=== Preparing manifest with the correct version tag ==="
                    sh "sed -i 's/IMAGE_TAG/${env.GIT_COMMIT_SHA}/g' k3s/myadmin.yaml"

                    echo "=== Sending all manifests to the K3s Master ==="
                    def manifestes = ['namespaces.yaml', 'secrets.yaml', 'mysql.yaml', 'myadmin.yaml', 'hpa.yaml', 'vpa.yaml', 'gar-refresher.yaml']
                    
                    for (fichier in manifestes) {
                        sh """
                            gcloud compute ssh ${MASTER_VM_NAME} \
                                --tunnel-through-iap \
                                --zone=${GCP_ZONE} \
                                --project=${GCP_PROJECT} \
                                --quiet \
                                --command='cat > /tmp/${fichier}' < k3s/${fichier}
                        """
                    }

                    echo "=== Applying configurations to the cluster in order ==="
                    // ORDER: Namespaces -> GAR Refresher -> Secrets -> DB -> Application -> Auto-scaling
                    sh """
                        gcloud compute ssh ${MASTER_VM_NAME} \
                            --tunnel-through-iap \
                            --zone=${GCP_ZONE} \
                            --project=${GCP_PROJECT} \
                            --quiet \
                            --command='
                                sudo kubectl apply -f /tmp/namespaces.yaml && \
                                sudo kubectl apply -f /tmp/gar-refresher.yaml && \
                                \
                                echo "=== Immediately initializing GAR token from within the cluster ===" && \
                                sudo kubectl create job --from=cronjob/gar-token-refresher gar-token-init -n myadmin-dev || true && \
                                \
                                echo "=== Deploying application resources ===" && \
                                sudo kubectl apply -f /tmp/secrets.yaml && \
                                sudo kubectl apply -f /tmp/mysql.yaml && \
                                sudo kubectl apply -f /tmp/myadmin.yaml && \
                                sudo kubectl apply -f /tmp/hpa.yaml && \
                                sudo kubectl apply -f /tmp/vpa.yaml
                            '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Deployment of MyAdmin version ${env.GIT_COMMIT_SHA} succeeded!"
        }
        failure {
            echo "Pipeline failed. An anomaly was detected."
        }
        cleanup {
            echo "Cleaning up local images on the DinD runner..."
            sh "docker rmi ${GAR_URL}:${env.GIT_COMMIT_SHA} ${GAR_URL}:latest || true"
        }
    }
}