global class RelayOnboardActionRequest {
    @InvocableVariable(label='1. Default Relay Trigger ID' required=false description='The default Relay Trigger ID to use if one if not specified on the individual request')
    public String triggerId;

    @InvocableVariable(label='2. Deactivate Previous Connections' required=false)
    public Boolean deactivatePreviousConnections;

    @InvocableVariable(Label='3. Single Request' required=false description='')
    public RelayOnboardingRequest singleRequest;

    @InvocableVariable(label='4. Batch Request' required=false description='')
    public List<RelayOnboardingRequest> batchRequest;

    @InvocableVariable(label='5. Dynamic input_ Names' required=false description='')
    public List<String> dynamicInputFieldNames;

    @InvocableVariable(label='6. Dynamic input_ Names & Values' required=false description='')
    public List<RelayDynamicInput> dynamicInputs;

    @InvocableVariable(label='7. Ext Data' required=false description='')
    public List<RelayDynamicInput> extData;

    @InvocableVariable(label='8. Send via Future' required=false)
    public Boolean useFuture;
}