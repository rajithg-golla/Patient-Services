public with sharing class RelayCustomer {
    public String ccid;
    public String secondary_account_id;
    public String first_name;
    public String middle_name;
    public String last_name;
    public String date_of_birth;
    public String ssn_last4;
    public String gender;
    public List<Address> addresses;
    public List<Notification> notification_channels;
    public List<ExtFields> ext;

    public RelayCustomer() {
        addresses = new List<Address>();
        notification_channels = new List<Notification>();
    }

    public with sharing class Address {
        public String address1;
        public String address2;
        public String city;
        public String state_province;
        public String postal_code;
        public String country;
    }

    public with sharing class Notification {
        public String channel_type;
        public String channel_addr;
        public String consent_type;
    }

    public with sharing class ExtFields {
        public String name;
        public String value;
    }
}

/*
Test Code

RelayCustomer rc = new RelayCustomer();
rc.ccid = '1001';
rc.first_name = 'steve';
RelayCustomer.Address rca = new RelayCustomer.Address();
rca.address1 = '201 KoP Road';
rca.city = 'Radnor';
rca.state_province = 'PA';
rc.addresses.add(rca);
String str = JSON.serialize(rc);
System.debug(str);

*/