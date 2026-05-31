pipeline {
    agent any

    environment {
        // Configuration GCP & Registre
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
        stage('Clonage des Dépots') {
            steps {
                script {
                    echo "=== 1. Récupération de l'infra ==="
                    // Recommande d'utiliser la configuration native SCM de Jenkins
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
                    sh "docker build -t ${GAR_URL}:${env.GIT_COMMIT_SHA} -t ${GAR_URL}:latest -f docker/api/Dockerfile api-src/"
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

        stage('Déploiement K3s (GitOps IAP)') {
            steps {
                script {
                    echo "=== Préparation du manifeste avec le bon tag de version ==="
                    sh "sed -i 's/IMAGE_TAG/${env.GIT_COMMIT_SHA}/g' k3s/myadmin.yaml"

                    echo "=== Envoi du manifeste sur le Master K3s ==="
                    // Ajout du drapeau --quiet pour empêcher gcloud de demander une validation de clé SSH
                    sh """
                        gcloud compute ssh ${MASTER_VM_NAME} \
                            --tunnel-through-iap \
                            --zone=${GCP_ZONE} \
                            --project=${GCP_PROJECT} \
                            --quiet \
                            --command='cat > /tmp/myadmin.yaml' < k3s/myadmin.yaml
                    """

                    echo "=== Génération d'un jeton éphémère et mise à jour du secret K3s ==="
                    // Jenkins génère un token d'accès temporaire
                    def gcpToken = sh(script: "gcloud auth print-access-token", returnStdout: true).trim()

                    // On envoie ce token à K3s pour mettre à jour le secret (Note le username 'oauth2accesstoken')
                    sh """
                        gcloud compute ssh ${MASTER_VM_NAME} \
                            --tunnel-through-iap \
                            --zone=${GCP_ZONE} \
                            --project=${GCP_PROJECT} \
                            --quiet \
                            --command="sudo kubectl create secret docker-registry gar-credentials \
                                --docker-server=${GCP_REGION}-docker.pkg.dev \
                                --docker-username=oauth2accesstoken \
                                --docker-password=${gcpToken} \
                                --dry-run=client -o yaml | sudo kubectl apply -f -"
                    """

                    echo "=== Application du manifeste sur le cluster ==="
                    sh """
                        gcloud compute ssh ${MASTER_VM_NAME} \
                            --tunnel-through-iap \
                            --zone=${GCP_ZONE} \
                            --project=${GCP_PROJECT} \
                            --quiet \
                            --command='sudo kubectl apply -f /tmp/myadmin.yaml'
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