public with sharing class PJN_CRMConnectionSettingMockUtil {

    private PJN_CRMConnectionSettingMockUtil(){} // NOPMD

    public static PJN_CRMConnectionSettingMock getInstance() {
        return new PJN_CRMConnectionSettingMock();
    }

    public static Object createMock(Type typeToMock) {
        // Invoke the stub API and pass it our mock provider to create a
        // mock class of typeToMock.
        return Test.createStub(typeToMock, PJN_CRMConnectionSettingMockUtil.getInstance());
    }
}