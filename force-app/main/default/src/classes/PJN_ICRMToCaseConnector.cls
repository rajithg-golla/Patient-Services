/**
 * @author      Mavens
 * @description Interface describing an implementation of CRM Enrollment integration connector.
 */
public interface PJN_ICRMToCaseConnector {
    Boolean syncEscalatedCases(PJN_CRM_Connection_Setting__mdt connectionSetting, Id recordId);
}