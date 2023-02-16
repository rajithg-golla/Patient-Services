/**
 * @author Mavens
 * @date 2020-01-06
 * @group PJN_TriggerDispatcher
 * dispatcher for the trigger logic
 */
public with sharing class PJN_TriggerDispatcher {

    /**
     * query to get all trigger handler setting records
     */
    @TestVisible private PJN_TriggerHandlerSettingQuery triggerHandlerSettingQuery =
        new PJN_TriggerHandlerSettingQuery();

    /**
     * map to enable mapping event picklist from the CMT to the actual Enum for adding
     */
    private static Map<String, System.TriggerOperation> operationsTypeByName {
        get {
            if(operationsTypeByName == null) {
                operationsTypeByName = new Map<String, System.TriggerOperation>();
                for(System.TriggerOperation thisOperationType : System.TriggerOperation.values()) {
                    operationsTypeByName.put(thisOperationType.name(), thisOperationType);
                }
            }
            return operationsTypeByName;
        }
        set;
    }

    /**
     * Represents the Trigger Operation Type
     */
    @testVisible
    private System.TriggerOperation operationType = Trigger.operationType;

    /**
     * Represents a map of the Trigger Handlers by Trigger Operations
     */
    private Map<System.TriggerOperation, List<HandlerInterface>> handlersByOperationTypes =
        new Map<System.TriggerOperation, List<HandlerInterface>>();

    /**
     * Used to add a new handler
     * @param   operationType Operation Type
     * @param   handler       Handler
     * @returns PJN_TriggerDispatcher
     * @example
     * new PJN_TriggerDispatcher()
     *      .add(TriggerOperation.BEFORE_INSERT, new SampleHandler());
     */
    public PJN_TriggerDispatcher add(System.TriggerOperation operationType, HandlerInterface handler) {
        if (!handlersByOperationTypes.containsKey(operationType)) {
            handlersByOperationTypes.put(operationType, new List<HandlerInterface>{handler});
        } else {
            handlersByOperationTypes.get(operationType).add(handler);
        }

        return this;
    }

    /**
     * adds new handlers from the trigger handler setting records
     * @returns `PJN_TriggerDispatcher`
     * @exception `PJN_TriggerDispatcherException` throws Trigger Handler Exception if records are incorrect
     * @example
     * new PJN_TriggerDispatcher()
     *      .addTriggerHandlerSettingRecords();
     */
    public PJN_TriggerDispatcher addTriggerHandlerSettingRecords() {
        try {
            SObjectType thisSObjectType = (
                trigger.new != null
                    ? trigger.new.get(0).getSObjectType()
                    : trigger.old.get(0).getSObjectType()
            );
            for(PJN_Trigger_Handler_Setting__mdt thisTriggerHandler : triggerHandlerSettingQuery.queryBySObjectType(thisSObjectType)) {
                Type classType = Type.forName(thisTriggerHandler.PJN_Class__c);
                if(classType != null) {
                    this.add(
                        operationsTypeByName.get(thisTriggerHandler.PJN_Event__c),
                        (PJN_TriggerDispatcher.HandlerInterface) classType.newInstance()
                    );
                }
            }
            return this;
        } catch(Exception ex) {
            throw new PJN_TriggerDispatcherException(ex);
        }
    }

    /**
     * dispatch the handlers by Trigger Operation Type
     * @example
     * new PJN_TriggerDispatcher()
     *      .add(TriggerOperation.BEFORE_INSERT, new SampleHandler())
     *      .dispatch();
     */
    public void dispatch() {
        List<HandlerInterface> handlers = handlersByOperationTypes.get(this.operationType);
        if (handlers != null) {
            for (HandlerInterface handler : handlers) {
                handler.handle();
            }
        }
    }

    /**
     * Trigger Handler Exception
     */
    public class PJN_TriggerDispatcherException extends Exception {}

    /**
     * Trigger Handler Interface
     */
    public interface HandlerInterface {
        void handle();
    }
}