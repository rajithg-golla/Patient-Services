/**
* @author Mavens
* @group UUID
* @description generates a universal unique identifier
* @example
* UUID: 95ecc380-afe9-11e4-9b6c-751b66dd541e
*/
public class PJN_UUIDGenerator {
    /**
    * @description generates and returns universalu nique identifier (UUID)
    * @returns String randomUUID
    */
    public static String randomUUID() {
        Blob thisBlob = Crypto.GenerateAESKey(128);
        String thisHex = EncodingUtil.ConvertToHex(thisBlob);
        return thisHex.SubString(0,8) + '-' +
               thisHex.SubString(8,12) + '-' +
               thisHex.SubString(12,16) + '-' +
               thisHex.SubString(16,20) + '-' +
               thisHex.substring(20);
    }
}