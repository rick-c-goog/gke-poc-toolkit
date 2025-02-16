/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Performs necessary steps to attach service project to Shared VPC host project
// Modules and resources below do not get executed if SHARED_VPC=false
module "enabled_shared_vpc_apis" {
  count   = var.shared_vpc ? 1 : 0
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 10.0"

  project_id                  = var.shared_vpc_project_id
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
}

resource "google_compute_subnetwork_iam_binding" "subnet_networkuser" {
  count      = var.shared_vpc ? 1 : 0
  project    = var.shared_vpc_project_id
  region     = var.region
  subnetwork = var.shared_vpc_subnet_name
  role       = "roles/compute.networkUser"
  members = [
    "serviceAccount:${local.clu_service_account}",
    "serviceAccount:${local.prj_service_account}",
  ]
}

resource "google_project_iam_binding" "shared_vpc_serviceagent" {
  count   = var.shared_vpc ? 1 : 0
  role    = "roles/container.hostServiceAgentUser"
  project = var.shared_vpc_project_id
  members = [
    "serviceAccount:${local.clu_service_account}",
  ]
}

resource "google_compute_shared_vpc_service_project" "attach_toolkit" {
  count = var.shared_vpc ? 1 : 0
  depends_on = [
    google_compute_subnetwork_iam_binding.subnet_networkuser,
    google_project_iam_binding.shared_vpc_serviceagent,
  ]
  host_project    = var.shared_vpc_project_id
  service_project = var.project_id
}
