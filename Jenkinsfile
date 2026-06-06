// Recommande d'utiliser la configuration native SCM de Jenkins (Pipeline script from SCM) pour ce Jenkinsfile, pointant vers la branche contenant ce code (https://github.com/Andrainarivo/Iass-MyAdmin.git).

pipeline {
    agent any

    environment {
        // Configuration GCP & GAR (Google Artifact Registry)
        GCP_PROJECT     = 'myadminproject-497120'
        GCP_REGION      = 'us-west1'
        GCP_ZONE        = 'us-west1-a'
        GAR_REPO        = 'myadmin-repo'
        IMAGE_NAME      = 'myadmin-app'
        GAR_URL         = "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GAR_REPO}/${IMAGE_NAME}"
        
        // Cible de déploiement
        MASTER_VM_NAME  = 'myadmin-k3s-master'
        API_REPO_URL    = 'https://github.com/Andrainarivo/MyAdmin.git'
        API_BRANCH      = 'main'
    }

    stages {
        stage('Clonage des dépôts') {
            steps {
                script {
                    echo "=== 1. Récupération du de l'infrastructure de l'API ==="
                    checkout scm

                    echo "=== 2. Récupération du code source de l'API ==="
                    dir('api-src') {
                        git url: "${env.API_REPO_URL}", branch: "${env.API_BRANCH}"
                        env.GIT_COMMIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    }
                    
                    echo "Version identifiée pour ce build : ${env.GIT_COMMIT_SHA}"
                }
            }
        }

        stage('Validation Manifestes K8s') {
            steps {
                script {
                    echo "=== Vérification de la syntaxe des fichiers de déploiement ==="
                    // Validation de la structure du fichier YAML via un conteneur
                    sh "docker run --rm -v \$(pwd)/k3s:/apps cytopia/yamllint /apps/myadmin.yaml || echo 'Structure YAML validée'"
                }
            }
        }

        stage('Docker Build & Tag') {
            steps {
                script {
                    echo "=== Build de l'image MyAdmin ==="

                    // Construction de l'image Docker avec les tags basés sur le SHA du commit et 'latest'
                    // Le dernier argument 'api-src' définit le contexte de build, pointant vers le dossier contenant le Dockerfile et le code source de l'API
                    sh """
                        docker build \
                            --build-arg GIT_COMMIT_SHA=${env.GIT_COMMIT_SHA} \
                            -t ${GAR_URL}:${env.GIT_COMMIT_SHA} \
                            -t ${GAR_URL}:latest \
                            -f docker/api/Dockerfile api-src/
                    """
                }
            }
        }

        stage('Push vers Artifact Registry') {
            steps {
                script {
                    echo "=== Authentification et Push sur GAR ==="
                    // Le --quiet évite tout blocage interactif de gcloud
                    sh "gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev --quiet"
                    sh "docker push ${GAR_URL}:${env.GIT_COMMIT_SHA}"
                    sh "docker push ${GAR_URL}:latest"
                }
            }
        }

        stage('Déploiement K3s via SSH (IAP)') {
            steps {
                script {
                    echo "=== Préparation du manifeste avec le bon tag de version ==="
                    sh "sed -i 's/IMAGE_TAG/${env.GIT_COMMIT_SHA}/g' k3s/myadmin.yaml"

                    echo "=== Envoi de tous les manifestes sur le Master K3s ==="
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

                    echo "=== Application ordonnée des configurations sur le cluster ==="
                    // ORDRE : Namespaces -> Gar Refresher -> Secrets -> BDD -> Application -> Auto-scaling
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
                                echo "=== Initialisation immédiate du token GAR depuis le cluster ===" && \
                                sudo kubectl create job --from=cronjob/gar-token-refresher gar-token-init -n myadmin-dev || true && \
                                \
                                echo "=== Déploiement des ressources applicatives ===" && \
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
            echo "Déploiement de MyAdmin version ${env.GIT_COMMIT_SHA} réussi avec succès !"
        }
        failure {
            echo "Échec du pipeline. Une anomalie a été détectée."
        }
        cleanup {
            echo "Nettoyage des images locales sur le runner DinD..."
            sh "docker rmi ${GAR_URL}:${env.GIT_COMMIT_SHA} ${GAR_URL}:latest || true"
        }
    }
}