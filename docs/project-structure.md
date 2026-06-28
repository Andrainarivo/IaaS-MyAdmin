# Documentation: Project Structure

This document details the structure of the `IaaS-MyAdmin` project and the role of each component.

## Directory Tree

```text
IaaS-MyAdmin/
├── docs/
│   ├── local-development.md
│   ├── project-structure.md
│   └── terraform-guide.md
├── docker/
│   └── api/
│       └── docker-compose.yml
│   └── jenkins/
├── k3s/
│   ├── hpa.yaml
│   └── myadmin.yaml
│   └── ...
└── terraform/
    ├── modules/
    │   └── firewalls/
    │   └── instances/
    │   └── networks/
    │   └── registry/
    ├── scripts/
    │   ├── addons.sh
    │   └── jenkins.sh
    │   └── master.sh
    │   └── worker.sh
    ├── provisioning.tf
    └── variables.tf
```

---

### Répertoire `docs/`

Contient toute la documentation du projet.

- `project-structure.md`: Ce fichier.
- `terraform-guide.md`: Instructions pour le déploiement de l'infrastructure avec Terraform.
- `local-development.md`: Guide pour lancer l'environnement de développement local.

### Répertoire `docker/`

Contient les configurations pour faire tourner l'application en local.

- `docker/api/docker-compose.yml`: Définit les services `api` et `db` (MySQL) pour un environnement de développement rapide. Il gère les volumes, les variables d'environnement et les dépendances entre services.

### Répertoire `k3s/`

Contient les manifestes Kubernetes pour déployer l'application `MyAdmin` sur le cluster.

- `myadmin.yaml`: Définit trois objets Kubernetes essentiels :
  - **Deployment**: Décrit l'état désiré de l'application (image, nombre de réplicas, ressources, variables d'environnement).
  - **Service**: Expose le Deployment en interne dans le cluster via un `ClusterIP`.
  - **Ingress**: Gère l'accès externe au Service, permettant au trafic HTTP d'atteindre l'application.
- `hpa.yaml`: Définit un `HorizontalPodAutoscaler` qui ajuste automatiquement le nombre de pods du `Deployment` en fonction de l'utilisation du CPU.

### Répertoire `terraform/`

Contient tout le code Infrastructure as Code (IaC) pour provisionner l'environnement sur GCP.

- `provisioning.tf`: Orchestre l'exécution de scripts de provisionnement sur les VMs après leur création. Il utilise `local-exec` pour se connecter en SSH via IAP et installer K3s.
- `variables.tf`: Définit les variables globales du projet Terraform (ID du projet, région, etc.).
- `modules/instances/`: Un module Terraform réutilisable pour créer les instances GCP (master, workers, Jenkins) ainsi que les comptes de service et permissions IAM associés.
- `scripts/`: Scripts shell exécutés par les provisioners Terraform.
  - `master.sh`: Script d'installation du nœud master K3s.
  - `worker.sh` (non fourni): Script d'installation des nœuds workers K3s.
  - `addons.sh`: Script pour installer des composants additionnels comme le Vertical Pod Autoscaler (VPA).
