# Create VPC network
resource "google_compute_network" "vpc_network" {
    name = "journal-vpc"
    auto_create_subnetworks = false
}

# Create Public subnet
resource "google_compute_subnetwork" "public_subnet" {
    name          = "public"
    ip_cidr_range = "10.0.1.0/24"
    region        = "us-central1"
    network       = google_compute_network.vpc_network.id
}

# Create private subnet 
resource "google_compute_subnetwork" "private_subnet" {
    name                     = "private"
    ip_cidr_range            = "10.0.2.0/24"
    region                   = "us-central1"
    network                  = google_compute_network.vpc_network.id
    private_ip_google_access = true
}

# --- PRIVATE SERVICE ACCESS (SQL PEERING) ---

# Reserve internal IP for Cloud SQL PSA 
resource "google_compute_global_address" "private_ip_alloc" {
    name          = "journal-vpc-ip-range-1772942934135"
    purpose       = "VPC_PEERING"
    address_type  = "INTERNAL"
    prefix_length = 16
    network       = google_compute_network.vpc_network.id
}

# Create the peering connection
resource "google_service_networking_connection" "default" {
    network                 = google_compute_network.vpc_network.id
    service                 = "servicenetworking.googleapis.com"
    reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# --- CLOUD SQL ---

# Create CloudSQL Postgresql 15 
resource "google_sql_database_instance" "postgres_instance" {
    name             = "db" 
    database_version = "POSTGRES_15" 
    region           = "us-central1"

    depends_on = [google_service_networking_connection.default]

    settings {
        tier = "db-f1-micro" 
        ip_configuration {
            ipv4_enabled    = false 
            private_network = google_compute_network.vpc_network.id
        }
    }
}

# Add the database
resource "google_sql_database" "database" {
    name     = "career_journal"
    instance = google_sql_database_instance.postgres_instance.name
}

# Add user
resource "google_sql_user" "users" {
    name     = "user1"
    instance = google_sql_database_instance.postgres_instance.name
    password = "password" 
}

# --- DATABASE SETUP ---

# Give the SQL instance permission to read from bucket
resource "google_storage_bucket_iam_member" "viewer" {
  bucket = "journal-api-db"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_sql_database_instance.postgres_instance.service_account_email_address}"
}

# Import database_setup.sql 
resource "null_resource" "db_setup" {
  depends_on = [google_sql_database.database, google_sql_user.users]

  provisioner "local-exec" {
    command = <<EOT
      gcloud sql import sql ${google_sql_database_instance.postgres_instance.name} \
        gs://journal-api-db/database_setup.sql \
        --database=${google_sql_database.database.name} \
        --quiet
    EOT
  }
}

# --- GKE AUTOPILOT ---

# Create GKE Autopilot cluster
resource "google_container_cluster" "primary" {
    name = "journal-cluster"
    location = "us-central1"

    enable_autopilot = true

    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.private_subnet.name

    release_channel {
        channel = "REGULAR"
    }
}

# --- ARTIFACT REGISTRY ---

resource "google_artifact_registry_repository" "journal_repo" {
  location      = "us-central1"
  repository_id = "journal-repo"
  description   = "Docker repository for Journal API"
  format        = "DOCKER"
}