locals {
    account_id                  =   "975050324669"
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
    source_code_provider        = local.source_code_providers["bitbucket"]

    cert_manager_email          = "cpinto0594@gmail.com"

    providers                   =   {
        aws                     =   {
            version             =   "5.77.0"
        }
        kubernetes              =   {
            version             =   "2.33.0"
        }
        helm                    =   {
            version             =   "2.16.1"
        }
        kubectl                 =   {
            version             =   "1.14.0"
        }
        time                    =   {
            version             =   "0.11.2"
        }
        random                  =   {
            version             =   "3.6.3"
        }
        tls                  =   {
            version             =   "4.0.6"
        }
    }
}