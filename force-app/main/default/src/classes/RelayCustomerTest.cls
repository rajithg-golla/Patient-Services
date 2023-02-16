@isTest
public class RelayCustomerTest {

    static testMethod void testRelayCustomerObject() {
        RelayCustomer rcust = new RelayCustomer();
        rcust.ccid = '1001';

        System.assert(rcust.ccid == '1001');
        System.assert(rcust.addresses.size() == 0);
        System.assert(rcust.notification_channels.size() == 0);

    }
}