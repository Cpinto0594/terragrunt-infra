locals {
    apps_config                                 =   yamldecode(file("./configs/apps.yaml")).defaults
}