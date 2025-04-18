# Generate a random password for the PostgreSQL instance
resource "random_password" "db_password" {
  length  = 16
  special = false  # Avoid special characters that might cause issues
}

# Allocate IP address range for Private Services Access
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Create the peering connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on              = [google_project_service.servicenetworking]
}

# Create a Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "main" {
  name             = local.db_instance_name
  database_version = "POSTGRES_14"
  region           = local.region
  
  # Cheapest Cloud SQL settings suitable for dev/test
  settings {
    tier              = "db-f1-micro"  # Smallest available tier
    availability_type = "ZONAL"        # Single zone for cost savings
    disk_size         = 10             # Minimum disk size in GB
    disk_type         = "PD_HDD"       # Cheaper HDD storage
    
    backup_configuration {
      enabled            = true
      binary_log_enabled = false
      start_time         = "02:00"     # Backup at 2 AM
    }
    
    # IP configuration - Private IP for security
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      
      # Remove the overly permissive authorized networks configuration
      # Let's rely on private connectivity only for better security
    }
  }
  
  deletion_protection = false  # Set to true for production
  
  depends_on = [
    google_project_service.sqladmin,
    google_service_networking_connection.private_vpc_connection
  ]
}

# Create a database
resource "google_sql_database" "database" {
  name     = "pollapp"
  instance = google_sql_database_instance.main.name
}

# Create a user
resource "google_sql_user" "user" {
  name     = "pollapp"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

# Store the PostgreSQL credentials in Secret Manager
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "poll-app-db-credentials"
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "db_credentials_version" {
  secret = google_secret_manager_secret.db_credentials.id
  
  secret_data = jsonencode({
    username = google_sql_user.user.name
    password = google_sql_user.user.password
    database = google_sql_database.database.name
    instance = google_sql_database_instance.main.connection_name
  })
}

# Grant the GKE service account access to the secret
resource "google_secret_manager_secret_iam_member" "gke_secret_access" {
  secret_id = google_secret_manager_secret.db_credentials.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke_sa.email}"
} 