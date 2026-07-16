locals {
    account_id                  =   "324711057459"
    environment                 =   "dev"
    tg_role_name                =   "Developer"
    master_domain               =   "renderapps.net"
    r53_domain_name             =   "${local.environment}.${local.master_domain}"
    #prod-domain                =   "rnder.net"
    source_code_providers       =   {
        "github"                =   {
            base_url            = "https://github.com/"
        },
        "bitbucket"                =   {
            base_url            = "https://bitbucket.org/"
        }
    }
    source_code_provider        = local.source_code_providers["github"]

    cert_manager_email          = "cpinto0594@gmail.com"

    providers                   =   {
        aws                     =   {
            version             =   "6.54.0"
        }
        kubernetes              =   {
            version             =   "3.2.1"
        }
        helm                    =   {
            version             =   "3.2.0"
        }
        kubectl                 =   {
            version             =   "1.19.0"
        }
        time                    =   {
            version             =   "0.14.0"
        }
        random                  =   {
            version             =   "3.9.0"
        }
        tls                  =   {
            version             =   "4.3.0"
        }
    }
}