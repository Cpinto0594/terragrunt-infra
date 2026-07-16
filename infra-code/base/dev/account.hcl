locals {
    account_id                  =   "324711057459"
    environment                 =   "dev"
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