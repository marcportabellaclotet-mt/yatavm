locals {
  network_acls = {
    public_inbound = {
      "100" : {
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      }
      "101" : {
        rule_action     = "allow"
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        ipv6_cidr_block = "::/0"
      }
    }
    public_outbound = {
      "100" : {
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      }
      "101" : {
        rule_action     = "allow"
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        ipv6_cidr_block = "::/0"
      }
    }
    private_inbound = {
      "100" : {
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      }
      "101" : {
        rule_action     = "allow"
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        ipv6_cidr_block = "::/0"
      }
    }
    private_outbound = {
      "100" : {
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      }
      "101" : {
        rule_action     = "allow"
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        ipv6_cidr_block = "::/0"
      }
    }
  }
}